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
    controller_name == 'projects' ||
      (controller_name == 'reports' && action_name == 'index')
  end

  def display_tooltip(message, len = Constants::NAME_TRUNCATION_LENGTH)
    if message.strip.length > Constants::NAME_TRUNCATION_LENGTH
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
    if target_user.assignments_notification
      UserNotification.create(notification: notification, user: target_user)
    end
  end

  def smart_annotation_parser(text, team = nil)
    # sometimes happens that the "team" param gets wrong data: "{nil, []}"
    # so we have to check if the "team" param is kind of Team object
    team = nil unless team.is_a? Team
    new_text = smart_annotation_filter_resources(text)
    new_text = smart_annotation_filter_users(new_text, team)
    new_text
  end

  # Check if text have smart annotations of resources
  # and outputs a link to resource
  def smart_annotation_filter_resources(text)
    sa_reg = /\[\#(.*?)~(prj|exp|tsk|sam)~([0-9a-zA-Z]+)\]/
    new_text = text.gsub(sa_reg) do |el|
      match = el.match(sa_reg)
      case match[2]
      when 'prj'
        project = Project.find_by_id(match[3].base62_decode)
        next unless project
        if project.archived?
          "<span class='sa-type'>" \
          "#{sanitize_input(match[2])}</span> " \
          "#{link_to project.name,
                     projects_archive_path} #{I18n.t('atwho.res.archived')}"
        else
          "<span class='sa-type'>" \
          "#{sanitize_input(match[2])}</span> " \
          "#{link_to project.name,
                     project_path(project)}"
        end
      when 'exp'
        experiment = Experiment.find_by_id(match[3].base62_decode)
        next unless experiment
        if experiment.archived?
          "<span class='sa-type'>" \
          "#{sanitize_input(match[2])}</span> " \
          "#{link_to experiment.name,
                     experiment_archive_project_path(experiment.project)} " \
          "#{I18n.t('atwho.res.archived')}"
        else
          "<span class='sa-type'>"\
          "#{sanitize_input(match[2])}</span> " \
          "#{link_to experiment.name,
                     canvas_experiment_path(experiment)}"
        end
      when 'tsk'
        my_module = MyModule.find_by_id(match[3].base62_decode)
        next unless my_module
        if my_module.archived?
          "<span class='sa-type'>" \
          "#{sanitize_input(match[2])}</span> " \
          "#{link_to my_module.name,
                     module_archive_experiment_path(my_module.experiment)} " \
          "#{I18n.t('atwho.res.archived')}"
        else
          "<span class='sa-type'>" \
          "#{sanitize_input(match[2])}</span> " \
          "#{link_to my_module.name,
                     protocols_my_module_path(my_module)}"
        end
      when 'sam'
        sample = Sample.find_by_id(match[3].base62_decode)
        if sample
          "<span class='glyphicon glyphicon-tint'></span> " \
          "#{link_to(sample.name,
                     sample_path(sample.id),
                     class: 'sample-info-link')}"
        else
          "<span class='glyphicon glyphicon-tint'></span> " \
          "#{match[1]} #{I18n.t('atwho.res.deleted')}"
        end
      end
    end
    new_text
  end

  # Check if text have smart annotations of users
  # and outputs a popover with user information
  def smart_annotation_filter_users(text, team)
    sa_user = /\[\@(.*?)~([0-9a-zA-Z]+)\]/
    new_text = text.gsub(sa_user) do |el|
      match = el.match(sa_user)
      user = User.find_by_id(match[2].base62_decode)
      next unless user
      team ||= current_team
      popover_for_user_name(user, team)
    end
    new_text
  end

  # Generate smart annotation link for one user object
  def popover_for_user_name(user, team = nil)
    user_still_in_team = user.teams.include?(team)

    user_description = %(<div class='col-xs-4'>
      <img src='#{user_avatar_absolute_url(user, :thumb)}'
       alt='thumb'></div><div class='col-xs-8'>
      <div class='row'><div class='col-xs-9 text-left'><h5>
      #{user.full_name}</h5></div><div class='col-xs-3 text-right'>
      <span class='glyphicon glyphicon-remove' aria-hidden='true'></span>
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
                 time: user_t.created_at.strftime('%B %Y'))}
        </p></div></div></div>)
    else
      user_description += %(<p></p></div></div></div>)
    end

    user_name = user.full_name
    user_name << ' ' + I18n.t('atwho.res.removed') if !user_still_in_team

    raw("<img src='#{user_avatar_absolute_url(user, :icon_small)}'" \
        "alt='avatar' class='atwho-user-img-popover'>") +
      raw('<a onClick="$(this).popover(\'show\')" ' \
          'class="atwho-user-popover" data-container="body" ' \
          'data-html="true" tabindex="0" data-trigger="focus" ' \
          'data-placement="top" data-toggle="popover" data-content="') +
      raw(user_description) + raw('" >') + user_name + raw('</a>')
  end

  def user_avatar_absolute_url(user, style)
    unless user.avatar(style) == '/images/icon_small/missing.png'
      return user.avatar(style)
    end
    URI.join(Rails.application.routes.url_helpers.root_url,
             "/images/#{style}/missing.png").to_s
  end
end
