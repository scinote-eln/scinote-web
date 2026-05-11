# frozen_string_literal: true

module Reports::Docx::DrawStepChecklist
  def draw_step_checklist(checklist)
    team = @report_team
    user = @user
    settings = @settings

    items = checklist.checklist_items
    timestamp = checklist.created_at
    color = @color
    @docx.p
    @docx.p do
      text SmartAnnotations::TagToText.new(
        user,
        team,
        I18n.t('projects.reports.elements.step_checklist.checklist_name', name: checklist.name)
      ).text, italic: true
      text " | #{I18n.t('search.index.archived')} ", bold: true if checklist.archived?
      unless settings['exclude_timestamps']
        text '| ' if checklist.name.present?
        if checklist.archived?
          text I18n.t('projects.reports.elements.archived_metadata',
                      datetime: I18n.l(checklist.archived_on, format: :full),
                      user: checklist.archived_by&.full_name), color: color[:gray]
        else
          text I18n.t('projects.reports.elements.step_checklist.user_time',
                    timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
        end
      end
    end
    if items.any?
      @docx.ul do
        items.each do |item|
          li do
            lines = SmartAnnotations::TagToText.new(user, team, item.text).text.split("\n")

            lines.each_with_index do |line, index|
              # Add the text line
              text line

              # If this isn't the last line in the array, start a new paragraph for the next line
              br if index < lines.length - 1
            end

            text " (#{I18n.t('projects.reports.elements.step_checklist.checked')})", color: '2dbe61' if item.checked
          end
        end
      end
    end
  end
end
