# frozen_string_literal: true

module Reports::Docx::DrawMyModuleActivity
  def draw_my_module_activity(subject)
    my_module = MyModule.find_by_id(subject['id']['my_module_id'])
    return unless my_module

    activities = ActivitiesService.my_module_activities(my_module).order(created_at: subject['sort_order'])

    return false unless activities.any?

    color = @color
    @docx.p
    @docx.p I18n.t('projects.reports.elements.module_activity.name', my_module: my_module.name),
            bold: true, size: Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
    activities.each do |activity|
      activity_ts = activity.created_at
      activity_text = if activity.old_activity?
                        sanitize_input(activity.message)
                      else
                        sanitize_input(generate_activity_content(activity, true))
                      end
      @docx.p I18n.l(activity_ts, format: :full), color: color[:gray]
      html_to_word_converter(activity_text)
      @docx.p
    end
  end
end
