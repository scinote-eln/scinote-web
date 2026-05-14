# frozen_string_literal: true

module BreadcrumbsHelper
  private

  def generate_breadcrumbs(subject, breadcrumbs)
    return [] if subject.is_a?(NonExistantRecord)

    case subject
    when Project
      if subject.project_folder
        parent = subject.project_folder
      else
        parent = subject.team
      end
      url = experiments_path(project_id: subject.id)
    when Experiment
      parent = subject.project
      url = my_modules_experiment_path(subject)
    when MyModule
      parent = subject.experiment
      url = protocols_my_module_path(subject)
    when Protocol
      if subject.in_repository?
        parent = subject.team
        url = protocol_path(subject)
      else
        parent = subject.my_module
        url = protocols_my_module_path(subject.my_module)
      end
    when Step
      parent = subject.protocol
      if parent.in_repository?
        url = protocol_path(parent, step_id: subject.id)
      else
        if subject.archived?
          url = archive_my_module_path(parent.my_module, step_id: subject.id)
        else
          url = protocols_my_module_path(parent.my_module, step_id: subject.id)
        end
      end
    when StepText, Checklist
      step = subject.step
      parent = step.protocol
      if parent.in_repository?
        url = protocol_path(parent, step_id: subject.id)
      else
        if subject.archived? || step.archived?
          url = archive_my_module_path(parent.my_module, step_id: step.id, mode: :steps)
        else
          url = protocols_my_module_path(parent.my_module, step_id: step.id, mode: :steps)
        end
      end

      subject = step
    when FormResponse
      form_parent = subject.parent
      if form_parent.is_a?(Step)
        parent = form_parent.protocol
        if subject.archived? || step.archived?
          url = archive_my_module_path(parent.my_module, step_id: step.id, mode: :steps)
        else
          url = protocols_my_module_path(parent.my_module, step_id: step.id, mode: :steps)
        end
      end
    when Table
      if subject.step
        step = subject.step
        parent = step.protocol
        if parent.in_repository?
          url = protocol_path(parent, step_id: step.id)
        else
          if subject.archived? || step.archived?
            url = archive_my_module_path(parent.my_module, step_id: step.id, mode: :steps)
          else
            url = protocols_my_module_path(parent.my_module, step_id: step.id, mode: :steps)
          end
        end
      elsif subject.result
        result = subject.result
        if result.is_a?(ResultTemplate)
          parent = result.protocol
          url = protocol_result_templates_path(parent, result_id: result.id)
        else
          parent = result.my_module
          if subject.archived? || result.archived?
            url = archive_my_module_path(result.my_module, result_id: result.id, mode: :results)
          else
            url = my_module_results_path(result.my_module, result_id: result.id)
          end
        end
      end
    when Result
      parent = subject.my_module
      if subject.archived?
        url = archive_my_module_path(subject.my_module, result_id: subject.id, mode: :results)
      else
        url = my_module_results_path(subject.my_module, result_id: subject.id)
      end
    when ResultText
      result = subject.result
      if result.is_a?(ResultTemplate)
        parent = result.protocol
        url = protocol_result_templates_path(parent, result_id: result.id)
      else
        parent = result.my_module
        if subject.archived? || result.archived?
          url = archive_my_module_path(result.my_module, result_id: result.id, mode: :results)
        else
          url = my_module_results_path(result.my_module, result_id: result.id)
        end
      end

      subject = result
    when ResultTemplate
      parent = subject.protocol
      url = protocol_result_templates_path(parent, result_id: subject.id)
    when ProjectFolder
      if subject.parent_folder
        parent = subject.parent_folder
      else
        parent = subject.team
      end
      url = project_folder_path(subject)
    when RepositoryBase
      parent = subject.team
      url = repository_path(subject)
    when RepositoryRow
      parent = subject.repository
      params = {
        id: subject.repository_id,
        landing_page: true,
        row_id: subject.id
      }
      params[:archived] = true if subject.archived

      url = repository_path(params)
    when Report
      parent = subject.team

      url = if object.instance_of?(::Notification)
              reports_path(
                preview_report_id: subject.id,
                preview_type: object.params[:report_type],
                team_id: subject.team.id
              )
            else
              reports_path(team_id: subject.team.id)
            end
    when LabelTemplate
      parent = subject.team
      url = label_template_path(subject)
    when StorageLocation
      parent = subject.team
      url = if subject.container
              storage_location_path(subject, team: subject.team_id)
            else
              storage_locations_path(parent_id: subject.id, team: subject.team_id)
            end
    when Team
      parent = nil
      url = projects_path(team: subject.id)
    when Form
      parent = subject.team
      url = form_path(subject, team: subject.team_id)
    else
      return breadcrumbs.reverse
    end

    breadcrumbs << { name: subject.name, code: subject.try(:code), url: url } if subject.name.present?
    if parent
      generate_breadcrumbs(parent, breadcrumbs)
    else
      breadcrumbs.reverse
    end
  end
end
