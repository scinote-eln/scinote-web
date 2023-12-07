# frozen_string_literal: true

module ApplicationHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include InputSanitizeHelper

  def module_page?
    controller_name == 'my_modules' ||
      controller_name == 'my_module_repositories'
  end

  def experiment_page?
    controller_name == 'experiments'
  end

  def project_page?
    controller_name == 'projects' &&
      action_name.in?(%w(show experiment_archive))
  end

  def all_projects_page?
    controller_name == 'projects' && action_name.in?(%w(index archive))
  end

  def display_tooltip(message, len = Constants::NAME_TRUNCATION_LENGTH)
    return '' unless message

    if message.strip.length > len
      sanitize_input("<div class='modal-tooltip'> \
      #{truncate(message.strip, length: len)} \
      <span class='modal-tooltiptext'> \
      #{message.strip}</span></div>")
    else
      truncate(message.strip, length: len)
    end
  end

  def module_repository_page?
    controller_name == 'my_modules' && !@repository.nil?
  end

  def displayable_flash_type?(type)
    %w(success warning alert error notice).include?(type)
  end

  def flash_alert_class(type)
    case type
    when 'success'
      'alert-success'
    when 'warning'
      'alert-warning'
    when 'error', 'alert'
      'alert-danger'
    else
      'alert-info'
    end
  end

  def flash_icon_class(type)
    case type
    when 'error', 'warning'
      'fa-exclamation-triangle'
    else
      'fa-check-circle'
    end
  end

  def smart_annotation_notification(options = {})
    title = options.fetch(:title) { :title_must_be_present }
    message = options.fetch(:message) { :message_must_be_present }
    old_text = options[:old_text] || ''
    new_text = options[:new_text]
    subject = options[:subject]
    return if new_text.blank?

    sa_user = /\[\@(.*?)~([0-9a-zA-Z]+)\]/
    # fetch user ids from the previous text
    old_user_ids = []
    old_text.gsub(sa_user) do |el|
      match = el.match(sa_user)
      old_user_ids << match[2].base62_decode
    end
    # fetch user ids from the new text
    new_user_ids = []
    new_text.gsub(sa_user) do |el|
      match = el.match(sa_user)
      new_user_ids << match[2].base62_decode
    end
    # check if the user has been already mentioned
    annotated_users = []
    new_user_ids.each do |el|
      annotated_users << el unless old_user_ids.include?(el)
    end
    # restrict the list of ids and generate notification
    annotated_users.uniq.each do |user_id|
      target_user = User.find_by_id(user_id)
      next unless target_user

      generate_annotation_notification(target_user, title, subject)
    end
  end

  def generate_annotation_notification(target_user, title, subject)
    GeneralNotification.send_notifications(
      {
        type: :smart_annotation_added,
        title: sanitize_input(title),
        subject: subject,
        user: target_user
      }
    )
  end

  def custom_link_open_new_tab(text)
    text.gsub(/\<a /, '<a target=_blank ')
  end

  def smart_annotation_parser(text, team = nil, base64_encoded_imgs = false, preview_repository = false)
    # sometimes happens that the "team" param gets wrong data: "{nil, []}"
    # so we have to check if the "team" param is kind of Team object
    team = nil unless team.is_a?(Team)
    new_text = smart_annotation_filter_resources(text, team, preview_repository: preview_repository)
    smart_annotation_filter_users(new_text, team, base64_encoded_imgs: base64_encoded_imgs)
  end

  # Check if text have smart annotations of resources
  # and outputs a link to resource
  def smart_annotation_filter_resources(text, team, preview_repository: false)
    user = if !defined?(current_user) && @user
             @user
           else
             current_user
           end
    team ||= defined?(current_team) ? current_team : nil
    sanitize_input(SmartAnnotations::TagToHtml.new(user, team, text, preview_repository).html)
  end

  # Check if text have smart annotations of users
  # and outputs a popover with user information
  def smart_annotation_filter_users(text, team, base64_encoded_imgs: false)
    sa_user = /\[\@(.*?)~([0-9a-zA-Z]+)\]/
    text.gsub(sa_user) do |el|
      match = el.match(sa_user)
      user = User.find_by_id(match[2].base62_decode)
      next unless user

      popover_for_user_name(user, team, false, false, base64_encoded_imgs)
    end
  end

  # Generate smart annotation link for one user object
  def popover_for_user_name(user,
                            team = nil,
                            skip_user_status = false,
                            skip_avatar = false,
                            base64_encoded_imgs = false)

    (defined?(controller) ? controller : ApplicationController.new)
      .render_to_string(
        partial: 'shared/atwho_user_container',
        locals: {
          user: user,
          skip_avatar: skip_avatar,
          skip_user_status: skip_user_status,
          team: team,
          base64_encoded_imgs: base64_encoded_imgs
        },
        formats: :html
      )
  end

  # No more dirty hack
  def user_avatar_absolute_url(user, style, base64_encoded_imgs = false)
    avatar_link = user.avatar_variant(style)
    if user.avatar.attached?
      return user.convert_variant_to_base64(avatar_link) if base64_encoded_imgs

      avatar_link.processed.url(expires_in: Constants::URL_LONG_EXPIRE_TIME)
    elsif base64_encoded_imgs
      file_path = Rails.root.join('app', 'assets', *avatar_link.split('/'))
      encoded_data =
        File.open(file_path) do |file|
          Base64.strict_encode64(file.read)
        end

      "data:image/svg+xml;base64,#{encoded_data}"
    else
      avatar_link
    end
  rescue StandardError => e
    Rails.logger.error e.message
    'icon_small/missing.svg'
  end

  def sso_enabled?
    ENV['SSO_ENABLED'] == 'true'
  end

  def okta_configured?
    ApplicationSettings.instance.values['okta'].present?
  end

  def azure_ad_configured?
    ApplicationSettings.instance.values['azure_ad_apps'].present?
  end

  def wopi_enabled?
    ENV['WOPI_ENABLED'] == 'true'
  end

  # Check whether the wopi file can be edited and return appropriate response
  def wopi_file_edit_button_status(asset)
    file_ext = asset.file_name.split('.').last
    if Constants::WOPI_EDITABLE_FORMATS.include?(file_ext)
      edit_supported = true
      title = ''
    else
      edit_supported = false
      title = if Constants::FILE_TEXT_FORMATS.include?(file_ext)
                I18n.t('assets.wopi_supported_text_formats_title')
              elsif Constants::FILE_TABLE_FORMATS.include?(file_ext)
                I18n.t('assets.wopi_supported_table_formats_title')
              else
                I18n.t('assets.wopi_supported_presentation_formats_title')
              end
    end
    return edit_supported, title
  end

  def create_2fa_qr_code(user)
    user.assign_2fa_token!
    qr_code_url = ROTP::TOTP.new(user.otp_secret, issuer: 'SciNote').provisioning_uri(user.email)
    RQRCode::QRCode.new(qr_code_url).as_svg(module_size: 4)
  end

  def login_disclaimer
    # login_disclaimer: { title: "...", body: "...", action: "..." }
    ApplicationSettings.instance.values['login_disclaimer']
  end

  def show_grey_background?
    return false unless controller_name && action_name

    Extends::COLORED_BACKGROUND_ACTIONS.include?("#{controller_name}/#{action_name}")
  end
end
