# frozen_string_literal: true

module GlobalActivitiesHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper
  include Canaid::Helpers::PermissionsHelper
  include InputSanitizeHelper

  def generate_activity_content(activity, no_links: false, no_custom_links: false)
    parameters = {}
    activity.message_items.each do |key, value|
      parameters[key] =
        if value.is_a? String
          value
        elsif value['type'] == 'Time' # use saved date for printing
          I18n.l(Time.zone.at(value['value']), format: :full)
        elsif value['type'] == 'Date'
          I18n.l(Date.parse(value['value']), format: :full)
        else
          no_links ? generate_name(value) : generate_link(value, activity)
        end

      if key == 'comment' && parameters[key].strip.present?
        parameters[key] = '<i class="sn-icon sn-icon-comments"></i>' + parameters[key]
      end
    end

    if no_custom_links
      I18n.t("global_activities.content.#{activity.type_of}_html", **parameters.symbolize_keys)
    else
      custom_auto_link(
        I18n.t("global_activities.content.#{activity.type_of}_html", **parameters.symbolize_keys),
        team: activity.team
      )
    end
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    I18n.t('global_activities.index.content_generation_error', activity_id: activity.id)
  end

  def generate_link(message_item, activity)
    obj = if message_item['id']
            message_item['type'].constantize.find_by(id: message_item['id'])
          else
            message_item['type'].constantize.new
          end

    return message_item['value'] unless obj

    current_value = generate_name(message_item)
    team = activity.team
    path = ''

    case obj
    when UserGroup
      path = users_settings_team_user_group_path(obj.team, obj)
    when User
      return "[@#{obj.full_name}~#{obj.id.base62_encode}]"
    when Tag
      # Not link for now
      return current_value
    when Team
      path = projects_path(team: obj.id)
    when Repository
      path = repository_path(obj, team: obj.team.id)
    when RepositoryRow
      # Handle private repository rows
      return I18n.t('storage_locations.show.hidden') unless can_read_repository?(obj.repository)

      return current_value unless obj.repository

      path = repository_path(obj.repository, team: obj.repository.team.id)
    when RepositoryColumn
      return current_value unless obj.repository

      path = repository_path(obj.repository, team: obj.repository.team.id)
    when Project
      path = obj.archived? ? projects_path : experiments_path(project_id: obj)
    when Experiment
      return current_value unless obj.navigable?

      path = if obj.archived?
               experiments_path(project_id: obj.project, view_mode: :archived)
             else
               my_modules_experiment_path(obj)
             end
    when MyModule
      return current_value unless obj.navigable?

      path = if obj.archived?
               my_modules_experiment_path(obj.experiment, view_mode: :archived)
             else
               protocols_my_module_path(obj)
             end
    when Protocol
      if obj.my_module.nil?
        path = protocol_path(obj)
      elsif obj.my_module.navigable?
        path = protocols_my_module_path(obj.my_module)
      else
        return current_value
      end
    when Result
      return current_value unless obj.navigable?

      path = obj.archived? ? my_module_results_path(obj.my_module, result_id: obj.id, view_mode: :archived) : my_module_results_path(obj.my_module, result_id: obj.id)
    when Step
      return current_value unless obj.navigable?

      path = protocols_my_module_path(obj.my_module, step_id: obj.id)
    when Report
      preview_type = activity.type_of == 'generate_docx_report' ? :docx : :pdf
      path = reports_path(team: obj.team.id, preview_report_id: obj.id, preview_type: preview_type)
    when ProjectFolder
      path = if obj.new_record?
               projects_path(team: activity.team.id)
             else
               project_folder_path(obj, team: obj.team.id)
             end
    when StorageLocation
      path = if obj.container
               storage_location_path(obj, team: obj.team_id)
             else
               storage_locations_path(parent_id: obj.id, team: obj.team_id)
             end
    when Form
      path = form_path(obj, team: obj.team.id)
    else
      return current_value
    end
    route_to_other_team(path, team, current_value)
  end

  def generate_name(message_item)
    obj = if message_item['id']
            message_item['type'].constantize.find_by(id: message_item['id'])
          else
            message_item['type'].constantize.new
          end

    return I18n.t('storage_locations.show.hidden') if obj.is_a?(RepositoryRow) && !can_read_repository?(obj.repository)

    return I18n.t('projects.index.breadcrumbs_root') if obj.is_a?(ProjectFolder) && obj.new_record?

    return I18n.t('storage_locations.index.breadcrumbs_root') if obj.is_a?(StorageLocation) && obj.new_record?

    return message_item['value'] unless obj

    value = obj.public_send(message_item['value_for'] || 'name')
    value = I18n.t('global_activities.index.no_name') if value.blank?

    value
  end
end
