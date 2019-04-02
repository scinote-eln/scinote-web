# frozen_string_literal: true

module GlobalActivitiesHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include InputSanitizeHelper

  def generate_activity_content(activity, no_links = false)
    parameters = {}
    activity.values[:message_items].each do |key, value|
      parameters[key] =
        if value.is_a? String
          value
        elsif value[:type] == 'Time' # use saved date for printing
          l(Time.at(value[:value]), format: :full_date)
        else
          no_links ? generate_name(value) : generate_link(value, activity)
        end
    end
    sanitize_input(I18n.t("global_activities.content.#{activity.type_of}_html",
                          parameters.symbolize_keys))
  end

  def generate_link(message_item, activity)
    obj = message_item[:type].constantize.find_by_id(message_item[:id])
    return message_item[:value] unless obj

    current_value = generate_name(message_item)
    team = activity.team
    path = ''

    case obj
    when User
      return popover_for_user_name(obj, team, false, true)
    when Tag
      # Not link for now
      return current_value
    when Team
      path = projects_path
    when Repository
      path = repository_path(obj)
    when RepositoryRow
      path = repository_path(obj.repository)
    when RepositoryColumn
      path = repository_path(obj.repository)
    when Project
      path = obj.archived? ? projects_path : project_path(obj)
    when Experiment
      return current_value unless obj.navigable?

      path = obj.archived? ? experiment_archive_project_path(obj.project) : canvas_experiment_path(obj)
    when MyModule
      return current_value unless obj.navigable?

      path = obj.archived? ? module_archive_experiment_path(obj.experiment) : protocols_my_module_path(obj)
    when Protocol
      if obj.in_repository?
        path = protocols_path
      elsif obj.my_module.navigable?
        path = protocols_my_module_path(obj.my_module)
      else
        return current_value
      end
    when Result
      return current_value unless obj.navigable?

      path = obj.archived? ? archive_my_module_path(obj.my_module) : results_my_module_path(obj.my_module)
    when Step
      return current_value
    when Report
      path = reports_path
    else
      return current_value
    end
    route_to_other_team(path, team, current_value)
  end

  def generate_name(message_item)
    obj = message_item[:type].constantize.find_by_id(message_item[:id])
    return message_item[:value] unless obj

    value = obj.public_send(message_item[:value_for] || 'name')
    value = t('global_activities.index.no_name') if value.blank?

    value
  end
end
