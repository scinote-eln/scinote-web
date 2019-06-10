# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::MyModuleActivity
  def draw_my_module_activity(my_module, order)
    activities = ActivitiesService.my_module_activities(my_module).order(created_at: order)

    @docx.p
    @docx.p I18n.t 'projects.reports.elements.module_activity.name', my_module: my_module.name

    if activities.count.positive?
      activities.each do |activity|
        activity_ts = activity.created_at
        activity_text = if activity.old_activity?
                          sanitize_input(activity.message)
                        else
                          sanitize_input(generate_activity_content(activity, true, user: @user, team: @report_team))
                        end
        @docx.p I18n.l(activity_ts, format: :full), color: 'a0a0a0'
        html_to_word_converter(activity_text)
        @docx.p
      end
    else
      text I18n.t 'projects.reports.elements.module_activity.no_activity'
    end
  end
end

# rubocop:enable  Style/ClassAndModuleChildren
