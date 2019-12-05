# frozen_string_literal: true

module ApplicationHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include InputSanitizeHelper

  def module_page?
    controller_name == 'my_modules'
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

  def sample_types_page_project?
    controller_name == 'sample_types' &&
      @my_module.nil? &&
      @experiment.nil?
  end

  def sample_groups_page_project?
    controller_name == 'sample_groups' &&
      @my_module.nil? &&
      @experiment.nil?
  end

  def sample_types_page_my_module?
    controller_name == 'sample_types' && !@my_module.nil?
  end

  def sample_groups_page_my_module?
    controller_name == 'sample_groups' && !@my_module.nil?
  end

  def sample_groups_page_experiment?
    controller_name == 'sample_groups' &&
      @my_module.nil? &&
      !@experiment.nil?
  end

  def sample_types_page_expermient?
    controller_name == 'sample_types' &&
      @my_module.nil? &&
      !@experiment.nil?
  end

  def module_repository_page?
    controller_name == 'my_modules' && !@repository.nil?
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

  def smart_annotation_parser(text, team = nil, base64_encoded_imgs = false)
    # sometimes happens that the "team" param gets wrong data: "{nil, []}"
    # so we have to check if the "team" param is kind of Team object
    team = nil unless team.is_a? Team
    new_text = smart_annotation_filter_resources(text, team)
    new_text = smart_annotation_filter_users(new_text, team, base64_encoded_imgs)
    new_text
  end

  # Check if text have smart annotations of resources
  # and outputs a link to resource
  def smart_annotation_filter_resources(text, team)
    user = if !defined?(current_user) && @user
             @user
           else
             current_user
           end
    SmartAnnotations::TagToHtml.new(user, team, text).html
  end

  # Check if text have smart annotations of users
  # and outputs a popover with user information
  def smart_annotation_filter_users(text, team, base64_encoded_imgs = false)
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
      user_t = user.user_teams
                   .where('user_teams.team_id = ?', team)
                   .first
      user_description += %(<p>
        #{I18n.t('atwho.users.popover_html',
                 role: user_t.role.capitalize,
                 team: user_t.team.name,
                 time: I18n.l(user_t.created_at, format: :full_date))}
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

    html << " #{I18n.t('atwho.res.removed')}" unless skip_user_status || user_still_in_team
    html = '<span class="atwho-user-container">' + html + '</span>'
    html
  end

  # No more dirty hack
  def user_avatar_absolute_url(user, style, base64_encoded_imgs = false)
    avatar_link = user.avatar_variant(style)
    if user.avatar.attached?
      return user.convert_variant_to_base64(avatar_link) if base64_encoded_imgs

      avatar_link.processed.service_url(expires_in: Constants::URL_LONG_EXPIRE_TIME)
    else
      avatar_link
    end
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def wopi_enabled?
    ENV['WOPI_ENABLED'] == 'true'
  end
end
