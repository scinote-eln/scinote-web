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

    case obj
    when User
      popover_for_user_name(obj, activity.team, false, true)
    when Tag
      # Not link for now
      current_value
    when Team
      route_to_other_team(projects_path(team: obj), obj, current_value)
    when Repository
      link_to(current_value, repository_path(obj))
    when RepositoryRow
      link_to(current_value, repository_path(obj.repository))
    when RepositoryColumn
      link_to(current_value, repository_path(obj.repository))
    when Project
      path = obj.archived? ? projects_path : project_path(obj)
      link_to(current_value, path)
    when Experiment
      return current_value unless obj.navigable?
      path = obj.archived? ? experiment_archive_project_path(obj.project) : canvas_experiment_path(obj)
      link_to(current_value, path)
    when MyModule
      return current_value unless obj.navigable?
      path = obj.archived? ? module_archive_experiment_path(obj.experiment) : protocols_my_module_path(obj)
      link_to(current_value, path)
    when Protocol
      if obj.in_repository?
        route_to_other_team(protocols_path, obj.team, current_value)
      elsif obj.my_module.navigable?
        link_to(current_value, protocols_my_module_path(obj.my_module))
      else
        current_value
      end
    when Result
      return current_value unless obj.navigable?
      path = obj.archived? ? archive_my_module_path(obj.my_module) : results_my_module_path(obj.my_module)
      link_to(current_value, path)
    else
      current_value
    end
  end
end
