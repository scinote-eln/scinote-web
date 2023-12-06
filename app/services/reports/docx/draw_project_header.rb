# frozen_string_literal: true

module Reports::Docx::DrawProjectHeader
  def draw_project_header(subject)
    project = subject.project
    link_style = @link_style
    scinote_url = @scinote_url
    color = @color

    return unless project && can_read_project?(@user, project)

    @docx.h1 do
      link I18n.t('projects.reports.elements.project_header.title', project: project.name),
           scinote_url + Rails.application.routes.url_helpers.experiments_path(project_id: project),
           link_style
    end

    @docx.p do
      text I18n.t('projects.reports.elements.project_header.user_time', code: project.code,
                  timestamp: I18n.l(project.created_at, format: :full)), color: color[:gray]
      br
    end
  end
end
