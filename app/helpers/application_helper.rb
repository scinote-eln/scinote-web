# frozen_string_literal: true

module ApplicationHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include InputSanitizeHelper

  $current_user_team = nil

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
    new_text = options.fetch(:new_text) { :new_text_must_be_present }
    old_text = options[:old_text] || ''
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

      generate_annotation_notification(target_user, title, message)
    end
  end

  def generate_annotation_notification(target_user, title, message)
    notification = Notification.create(
      type_of: :assignment,
      title: sanitize_input(title),
      message: sanitize_input(message)
    )
    UserNotification.create(notification: notification, user: target_user) if target_user.assignments_notification
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
    SmartAnnotations::TagToHtml.new(user, team, text, preview_repository).html
  end

  # Check if text have smart annotations of users
  # and outputs a popover with user information
  def smart_annotation_filter_users(text, team, base64_encoded_imgs: false)
    sa_user = /\[\@(.*?)~([0-9a-zA-Z]+)\]/
    new_text = text.gsub(sa_user) do |el|
      match = el.match(sa_user)
      user = User.find_by_id(match[2].base62_decode)
      next unless user

      popover_for_user_name(user, team, false, false, base64_encoded_imgs)
    end
    new_text
  end

  # Generate smart annotation link for one user object
  def popover_for_user_name(user,
                            team = nil,
                            skip_user_status = false,
                            skip_avatar = false,
                            base64_encoded_imgs = false)
    $current_user_team = team unless team.nil?
    user_still_in_team = user.teams.include?(team)

    user_description = %(<div class='col-xs-4'>
      <img src='#{user_avatar_absolute_url(user, :thumb, base64_encoded_imgs)}'
       alt='thumb'></div><div class='col-xs-8'>
      <div class='row'><div class='col-xs-9 text-left'><h5>
      #{user.full_name}</h5></div><div class='col-xs-3 text-right'>
      <span class='fas fa-times' aria-hidden='true'></span>
      </div></div><div class='row'><div class='col-xs-12'>
      <p class='silver'>#{user.email}</p>)
    if user_still_in_team
      user_team_assignment = user.user_assignments.find_by(assignable: team)
      user_description += %(<p>
        #{I18n.t('atwho.users.popover_html',
                 role: user_team_assignment.user_role.name.capitalize,
                 team: user_team_assignment.assignable.name,
                 time: I18n.l(user_team_assignment.created_at, format: :full_date))}
        </p></div></div></div>)
    else
      user_description += %(<p></p></div></div></div>)
    end

    user_name = user.full_name

    html = if skip_avatar
             ''
           else
             raw("<span class=\"global-avatar-container smart-annotation\">" \
                  "<img src='#{user_avatar_absolute_url(user, :icon_small, base64_encoded_imgs)}'" \
                  "alt='avatar' class='atwho-user-img-popover'" \
                  " ref='#{'missing-img' unless user.avatar.attached?}'></span>")
           end

    html =
      raw(html) +
      raw('<a onClick="$(this).popover(\'show\')" ' \
        'class="atwho-user-popover" data-container="body" ' \
        'data-html="true" tabindex="0" data-trigger="focus" ' \
        'data-placement="top" data-toggle="popover" data-content="') +
      raw(user_description) + raw('" >') + user_name + raw('</a>')

    html << " #{I18n.t('atwho.res.removed')}" unless skip_user_status || user.teams.include?($current_user_team)
    html = '<span class="atwho-user-container">' + html + '</span>'
    html
  end

  # No more dirty hack
  def user_avatar_absolute_url(user, style, base64_encoded_imgs = false)
    avatar_link = user.avatar_variant(style)
    if user.avatar.attached?
      return user.convert_variant_to_base64(avatar_link) if base64_encoded_imgs

      avatar_link.processed.service_url(expires_in: Constants::URL_LONG_EXPIRE_TIME)
    elsif base64_encoded_imgs
      file_path = Rails.root.join('app', 'assets', *avatar_link.split('/'))
      encoded_data =
        File.open(file_path) do |file|
          Base64.strict_encode64(file.read)
        end
      "data:#{avatar_link.split('.').last};base64,#{encoded_data}"
    else
      avatar_link
    end
  rescue StandardError => e
    Rails.logger.error e.message
    'icon_small/missing.png'
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
end
