# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::Experiment
  def draw_experiment(experiment, children)
    @docx.p I18n.t 'projects.reports.elements.experiment.user_time',
                   timestamp: I18n.l(experiment.created_at, format: :full)
    @docx.hr do
      spacing 1
    end
    @docx.h2 experiment.name
    @docx.p
    @docx.p SmartAnnotations::TagToText.new(@user, @report_team, experiment.description).text
    @docx.p
    @docx.p
    children.each do |my_module_hash|
      my_module = MyModule.find_by_id(my_module_hash['id']['my_module_id'])
      draw_my_module(my_module, my_module_hash['children'])
    end
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
