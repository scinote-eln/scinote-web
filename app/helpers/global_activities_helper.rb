# frozen_string_literal: true

module GlobalActivitiesHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include InputSanitizeHelper

  def generate_activity_content(activity)
    parameters = {}
    activity.values[:message_items].each do |key, value|
      parameters[key] =
        if value.is_a? String
          value
        else
          generate_link(value, activity)
        end
    end
    I18n.t("global_activities.content.#{activity.type_of}_html",
           parameters.symbolize_keys)
  end

  def generate_link(message_item, activity)
    type = message_item[:type]
    id = message_item[:id]
    getter = message_item[:getter]
    value = message_item[:value]

    obj = type.constantize.find_by_id id
    return value unless obj

    current_value = obj.public_send(getter || 'name')
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
    else
      return current_value
    end
    route_to_other_team(path, obj, current_value)
  end
end
