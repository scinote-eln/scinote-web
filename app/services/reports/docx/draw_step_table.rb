# frozen_string_literal: true

module Reports::Docx::DrawStepTable
  def draw_step_table(table)
    color = @color
    timestamp = table.created_at
    @docx.p
    @docx.table JSON.parse(table.contents_utf_8)['data'], border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE
    @docx.p do
      text I18n.t('projects.reports.elements.step_table.table_name', name: table.name), italic: true
      text ' '
      text I18n.t('projects.reports.elements.step_table.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
  end
end
