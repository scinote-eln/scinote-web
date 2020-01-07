# frozen_string_literal: true

module GlobalActivitiesHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include InputSanitizeHelper

  def generate_activity_content(activity, no_links = false)
    parameters = {}
    activity.message_items.each do |key, value|
      parameters[key] =
        if value.is_a? String
          value
        elsif value['type'] == 'Time' # use saved date for printing
          l(Time.at(value['value']), format: :full_date)
        else
          no_links ? generate_name(value) : generate_link(value, activity)
        end
    end
    custom_auto_link(
      I18n.t("global_activities.content.#{activity.type_of}_html", parameters.symbolize_keys),
      team: activity.team
    )
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    I18n.t('global_activities.index.content_generation_error', activity_id: activity.id)
  end

  def generate_link(message_item, activity)
    obj = message_item['type'].constantize.find_by_id(message_item['id'])
    return message_item['value'] unless obj

    current_value = generate_name(message_item)
    team = activity.team
    path = ''

    case obj
    when User
      return "[@#{obj.full_name}~#{obj.id.base62_encode}]"
    when Tag
      # Not link for now
      return current_value
    when Team
      path = projects_path
    when Repository
      path = repository_path(obj)
    when RepositoryRow
      return current_value unless obj.repository

      path = repository_path(obj.repository)
    when RepositoryColumn
      return current_value unless obj.repository

      path = repository_path(obj.repository)
    when Project
      path = obj.archived? ? projects_path : project_path(obj)
    when Experiment
      return current_value unless obj.navigable?

      path = obj.archived? ? experiment_archive_project_path(obj.project) : canvas_experiment_path(obj)
    when MyModule
      return current_value unless obj.navigable?

      path = if obj.archived?
               module_archive_experiment_path(obj.experiment)
             else
               path = if %w(assign_repository_record unassign_repository_record).include? activity.type_of
                        repository_my_module_path(obj, activity.values['message_items']['repository']['id'])
                      else
                        protocols_my_module_path(obj)
                      end
             end
    when Protocol
      if obj.in_repository_public?
        path = protocols_path(type: :public)
      elsif obj.in_repository_private?
        path = protocols_path(type: :private)
      elsif obj.in_repository_archived?
        path = protocols_path(type: :archive)
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
    obj = message_item['type'].constantize.find_by_id(message_item['id'])
    return message_item['value'] unless obj

    value = obj.public_send(message_item['value_for'] || 'name')
    value = I18n.t('global_activities.index.no_name') if value.blank?

    value
  end
end
