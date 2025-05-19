# frozen_string_literal: true

module Reports::Docx::DrawExperiment
  def draw_experiment(subject)
    color = @color
    link_style = @link_style
    settings = @settings
    scinote_url = @scinote_url
    experiment = subject.experiment
    return unless can_read_experiment?(@user, experiment)

    @docx.h2 do
      link  experiment.name,
            scinote_url + Rails.application.routes.url_helpers.my_modules_experiment_path(experiment),
            link_style
    end

    if !settings['exclude_timestamps'] || experiment.archived?
      @docx.p do
        unless settings['exclude_timestamps']
          text I18n.t('projects.reports.elements.experiment.user_time',
                      code: experiment.code,
                      timestamp: I18n.l(experiment.created_at, format: :full)), color: color[:gray]
          text ' | ' if experiment.archived?
        end
        text I18n.t('search.index.archived'), color: color[:gray] if experiment.archived?
      end
    end

    unless settings['exclude_task_metadata']
      if experiment.start_on.present?
        @docx.p do
          text I18n.t('projects.reports.elements.experiment.started_on',
                      started_on: I18n.l(experiment.start_on, format: :full))
        end
      end

      if experiment.due_date.present?
        @docx.p do
          text I18n.t('projects.reports.elements.experiment_header.due_date',
                      due_date: I18n.l(experiment.due_date, format: :full))
        end
      end

      status_color = Constants::STATUS_COLORS[experiment.status]

      @docx.p do
        text I18n.t('projects.reports.elements.experiment.status_label')
        text ' '
        text "[#{I18n.t("projects.reports.elements.experiment.status.#{experiment.status}")}]", color: status_color
      end
    end
    html = custom_auto_link(experiment.description, team: @report_team)
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: scinote_url,
                                              link_style: link_style }).html_to_word_converter(html)
    @docx.p
    subject.children.active.each do |child|
      public_send("draw_#{child.type_of}", child)
    end
  end
end
