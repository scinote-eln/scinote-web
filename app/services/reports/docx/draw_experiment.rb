# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawExperiment
=======
module DrawExperiment
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
module Reports::Docx::DrawExperiment
>>>>>>> Initial commit of 1.17.2 merge
  def draw_experiment(subject)
    color = @color
    link_style = @link_style
    scinote_url = @scinote_url
<<<<<<< HEAD
    experiment = subject.experiment
    return unless can_read_experiment?(@user, experiment)
=======
    experiment = Experiment.find_by_id(subject['id']['experiment_id'])
    return unless experiment
>>>>>>> Finished merging. Test on dev machine (iMac).

    @docx.h2 experiment.name, size: Constants::REPORT_DOCX_EXPERIMENT_TITLE_SIZE
    @docx.p do
      text I18n.t('projects.reports.elements.experiment.user_time',
<<<<<<< HEAD
                  code: experiment.code, timestamp: I18n.l(experiment.created_at, format: :full)), color: color[:gray]
=======
                  timestamp: I18n.l(experiment.created_at, format: :full)), color: color[:gray]
>>>>>>> Finished merging. Test on dev machine (iMac).
      if experiment.archived?
        text ' | '
        text I18n.t('search.index.archived'), color: color[:gray]
      end
      text ' | '
      link  I18n.t('projects.reports.elements.all.scinote_link'),
            scinote_url + Rails.application.routes.url_helpers.canvas_experiment_path(experiment),
            link_style
    end
    html = custom_auto_link(experiment.description, team: @report_team)
<<<<<<< HEAD
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: scinote_url,
                                              link_style: link_style }).html_to_word_converter(html)
    @docx.p
    subject.children.active.each do |child|
      public_send("draw_#{child.type_of}", child)
=======
    html_to_word_converter(html)
    @docx.p
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
>>>>>>> Finished merging. Test on dev machine (iMac).
    end
  end
end
