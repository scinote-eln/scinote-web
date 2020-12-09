# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawMyModuleActivity
<<<<<<< HEAD
  def draw_my_module_activity(my_module)
    activities = ActivitiesService.my_module_activities(my_module).order(created_at: :desc)
    return false if activities.blank?
=======
module DrawMyModuleActivity
=======
module Reports::Docx::DrawMyModuleActivity
>>>>>>> Initial commit of 1.17.2 merge
  def draw_my_module_activity(subject)
    my_module = MyModule.find_by_id(subject['id']['my_module_id'])
=======
  def draw_my_module_activity(subject, my_module)
>>>>>>> Pulled latest release
    return unless my_module

    activities = ActivitiesService.my_module_activities(my_module).order(created_at: subject['sort_order'])

    return false unless activities.any?
>>>>>>> Finished merging. Test on dev machine (iMac).

    color = @color
    @docx.p
    @docx.p I18n.t('projects.reports.elements.module_activity.name', my_module: my_module.name),
            bold: true, size: Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
    activities.each do |activity|
      activity_ts = activity.created_at
      activity_text = if activity.old_activity?
                        sanitize_input(activity.message)
                      else
<<<<<<< HEAD
                        sanitize_input(generate_activity_content(activity, no_links: true))
                      end
      @docx.p I18n.l(activity_ts, format: :full), color: color[:gray]
      Reports::HtmlToWordConverter.new(@docx).html_to_word_converter(activity_text)
=======
                        sanitize_input(generate_activity_content(activity, true))
                      end
      @docx.p I18n.l(activity_ts, format: :full), color: color[:gray]
<<<<<<< HEAD
      html_to_word_converter(activity_text)
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
      Reports::HtmlToWordConverter.new(@docx).html_to_word_converter(activity_text)
>>>>>>> Pulled latest release
      @docx.p
    end
  end
end
