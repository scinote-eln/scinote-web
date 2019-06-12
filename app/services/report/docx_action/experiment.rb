# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::Experiment
  def draw_experiment(experiment, children)
    link_style = @link_style
    scinote_url = @scinote_url
    @docx.h2 experiment.name
    @docx.p do
      text I18n.t('projects.reports.elements.experiment.user_time',
                  timestamp: I18n.l(experiment.created_at, format: :full)), color: 'a0a0a0'
      text ' | '
      link  'SciNote Link',
            scinote_url + Rails.application.routes.url_helpers.canvas_experiment_path(experiment),
            link_style
    end
    html = custom_auto_link(experiment.description, team: @report_team)
    html_to_word_converter(html)
    @docx.p
    children.each do |my_module_hash|
      my_module = MyModule.find_by_id(my_module_hash['id']['my_module_id'])
      draw_my_module(my_module, my_module_hash['children'])
    end
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
