# frozen_string_literal: true

module Reports::Docx::DrawMyModuleActivity
  def draw_my_module_activity(my_module)
    activities = ActivitiesService.my_module_activities(my_module).order(created_at: :desc)
    return false if activities.blank?

    color = @color
    @docx.p
    @docx.h4 I18n.t('projects.reports.elements.module_activity.name', my_module: my_module.name)
    activities.each do |activity|
      activity_ts = activity.created_at
      activity_text = if activity.old_activity?
                        sanitize_input(activity.message)
                      else
                        sanitize_input(generate_activity_content(activity, no_links: true))
                      end
      @docx.p I18n.l(activity_ts, format: :full), color: color[:gray]
      Reports::HtmlToWordConverter.new(@docx).html_to_word_converter(activity_text)
      @docx.p
    end
  end
end
