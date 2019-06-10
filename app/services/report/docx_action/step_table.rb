# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::StepTable
  def draw_step_table(table)
    timestamp = table.created_at
    @docx.p
    @docx.p do
      text I18n.t 'projects.reports.elements.step_table.table_name', name: table.name
      text ' '
      text I18n.t('projects.reports.elements.step_table.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: 'a0a0a0'
    end
    @docx.table JSON.parse(table.contents_utf_8)['data'], border_color: '666666'
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
