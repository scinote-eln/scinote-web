# frozen_string_literal: true

module BreadcrumbsHelper
  private

  def generate_breadcrumbs(subject, breadcrumbs)
    return [] if subject.is_a?(NonExistantRecord)

    case subject
    when Project
      parent = subject.team
      url = project_path(subject)
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
    when Result
      parent = subject.my_module
      view_mode = subject.archived? ? 'archived' : 'active'
      url = my_module_results_path(subject.my_module, view_mode:)
    when ProjectFolder
      parent = subject.team
      url = project_folder_path(subject)
    when RepositoryBase
      parent = subject.team
      url = repository_path(subject)
    when RepositoryRow
      parent = subject.repository
      url = repository_path(subject.repository, landing_page: true, row_id: subject.id)
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
    when Team
      parent = nil
      url = projects_path(team: subject.id)
    end

    breadcrumbs << { name: subject.name, url: } if subject.name.present?

    if parent
      generate_breadcrumbs(parent, breadcrumbs)
    else
      breadcrumbs.reverse
    end
  end
end
