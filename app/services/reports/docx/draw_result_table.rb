# frozen_string_literal: true

module Reports::Docx::DrawResultTable
  def draw_result_table(subject)
    result = Result.find_by_id(subject['id']['result_id'])
    return unless result

    table = result.table
    timestamp = table.created_at
    color = @color
    @docx.p
    @docx.p do
      text result.name, italic: true
      text ' ' + I18n.t('search.index.archived'), color: color[:gray] if result.archived?
      text ' '
      text I18n.t 'projects.reports.elements.result_table.table_name', name: table.name
      text ' '
      text I18n.t('projects.reports.elements.result_text.user_time',
                  timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: color[:gray]
    end
    @docx.table JSON.parse(table.contents_utf_8)['data'], border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
  end
end
