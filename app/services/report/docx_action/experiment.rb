module Report::DocxAction::Experiment
  def draw_experiment(experiment,children)
    @docx.p I18n.t "projects.reports.elements.experiment.user_time", timestamp: I18n.l(experiment.created_at, format: :full)
    @docx.hr
    @docx.h2 experiment.name
    @docx.p
    @docx.p SmartAnnotations::TagToText.new(@user, @team, experiment.description).text
    @docx.p
    @docx.p
    children.each do |my_module_hash|
      my_module = MyModule.find_by_id(my_module_hash['id']['my_module_id'])
      draw_my_module(my_module,my_module_hash['children'])
    end
  end
end
