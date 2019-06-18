# frozen_string_literal: true

module DrawExperiment
  def draw_experiment(subject)
    color = @color
    link_style = @link_style
    scinote_url = @scinote_url
    experiment = Experiment.find_by_id(subject['id']['experiment_id'])
    return unless experiment

    @docx.h2 experiment.name
    @docx.p do
      text I18n.t('projects.reports.elements.experiment.user_time',
                  timestamp: I18n.l(experiment.created_at, format: :full)), color: color[:gray]
      text ' | '
      link  'SciNote Link',
            scinote_url + Rails.application.routes.url_helpers.canvas_experiment_path(experiment),
            link_style
    end
    html = custom_auto_link(experiment.description, team: @report_team)
    html_to_word_converter(html)
    @docx.p
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
  end
end
