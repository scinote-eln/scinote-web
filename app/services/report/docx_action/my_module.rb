module Report::DocxAction::MyModule
  def draw_my_module(my_module,children)
    @docx.p I18n.t "projects.reports.elements.module.user_time", timestamp: I18n.l(my_module.created_at, format: :full)
    @docx.hr
    if my_module.due_date.present? 
      @docx.p I18n.t "projects.reports.elements.module.due_date", due_date: I18n.l(my_module.due_date, format: :full) do
        align :right
      end
    else
      @docx.p I18n.t "projects.reports.elements.module.no_due_date" do
        align :right
      end
    end
    @docx.h2 my_module.name
    if my_module.completed?
      @docx.p "#{I18n.t("my_modules.states.completed")} #{I18n.l(my_module.completed_on, format: :full)}"
    end
    @docx.p
    if my_module.description.present?
      html = SmartAnnotations::TagToHtml.new(@user, @team, my_module.description).html
      html_to_word_converter(html)
    else
      @docx.p I18n.t "projects.reports.elements.module.no_description" 
    end
  end
end