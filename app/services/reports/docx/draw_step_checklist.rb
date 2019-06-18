# frozen_string_literal: true

module DrawStepChecklist
  def draw_step_checklist(subject)
    checklist = Checklist.find_by_id(subject['id']['checklist_id'])
    return unless checklist

    items = checklist.checklist_items
    timestamp = checklist.created_at
    @docx.p
    @docx.p do
      text SmartAnnotations::TagToText.new(
        @user,
        @report_team,
        I18n.t('projects.reports.elements.step_checklist.checklist_name', name: checklist.name)
      ).text
      text ' '
      text I18n.t('projects.reports.elements.step_checklist.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: 'a0a0a0'
    end
    @docx.ul do
      items.each do |item|
        li do
          text SmartAnnotations::TagToText.new(@user, @report_team, item.text).text
          text " (#{I18n.t('projects.reports.elements.step_checklist.checked')})", color: '2dbe61' if item.checked
        end
      end
    end
  end
end
