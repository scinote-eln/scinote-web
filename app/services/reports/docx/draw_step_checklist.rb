# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawStepChecklist
<<<<<<< HEAD
<<<<<<< HEAD
  def draw_step_checklist(checklist)
    team = @report_team
    user = @user
=======
module DrawStepChecklist
=======
module Reports::Docx::DrawStepChecklist
>>>>>>> Initial commit of 1.17.2 merge
  def draw_step_checklist(subject)
=======
  def draw_step_checklist(subject, step)
>>>>>>> Pulled latest release
    team = @report_team
    user = @user
    checklist = step.checklists.find_by(id: subject['id']['checklist_id'])
    return unless checklist
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
  def draw_step_checklist(checklist)
    team = @report_team
    user = @user
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.

    items = checklist.checklist_items
    timestamp = checklist.created_at
    color = @color
    @docx.p
    @docx.p do
      text SmartAnnotations::TagToText.new(
<<<<<<< HEAD
<<<<<<< HEAD
        user,
        team,
=======
        @user,
        @report_team,
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
        user,
        team,
>>>>>>> Pulled latest release
        I18n.t('projects.reports.elements.step_checklist.checklist_name', name: checklist.name)
      ).text, italic: true
      text ' '
      text I18n.t('projects.reports.elements.step_checklist.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Pulled latest release
    if items.any?
      @docx.ul do
        items.each do |item|
          li do
            text SmartAnnotations::TagToText.new(user, team, item.text).text
            text " (#{I18n.t('projects.reports.elements.step_checklist.checked')})", color: '2dbe61' if item.checked
          end
<<<<<<< HEAD
=======
    @docx.ul do
      items.each do |item|
        li do
          text SmartAnnotations::TagToText.new(user, team, item.text).text
          text " (#{I18n.t('projects.reports.elements.step_checklist.checked')})", color: '2dbe61' if item.checked
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
>>>>>>> Pulled latest release
        end
      end
    end
  end
end
