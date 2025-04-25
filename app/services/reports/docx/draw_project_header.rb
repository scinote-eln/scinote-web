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

    unless @settings['exclude_timestamps']
      @docx.p do
        text I18n.t('projects.reports.elements.project_header.user_time', code: project.code,
                    timestamp: I18n.l(project.created_at, format: :full)), color: color[:gray]
        br
      end
    end

    unless @settings['exclude_task_metadata']
      if project.start_on.present?
        @docx.p do
          text I18n.t('projects.reports.elements.project_header.started_on',
                      started_on: I18n.l(project.start_on, format: :full))
        end
      end

      if project.due_date.present?
        @docx.p do
          text I18n.t('projects.reports.elements.project_header.due_date',
                      due_date: I18n.l(project.due_date, format: :full))
        end
      end

      if project.supervised_by.present?
        @docx.p do
          text I18n.t('projects.reports.elements.project_header.supervised_by', user: project.supervised_by.name)
        end
      end

      status_color = Constants::STATUS_COLORS[project.status]

      @docx.p do
        text I18n.t('projects.reports.elements.project_header.status_label')
        text ' '
        text "[#{I18n.t("projects.reports.elements.project_header.status.#{project.status}")}]", color: status_color
      end
    end

    if project.description.present?
      html = custom_auto_link(project.description, team: @report_team)
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: scinote_url,
                                                link_style: link_style }).html_to_word_converter(html)
    end
  end
end
