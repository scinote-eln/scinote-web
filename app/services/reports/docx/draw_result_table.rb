# frozen_string_literal: true

module Reports::Docx::DrawResultTable
  def draw_result_table(result)
    table = result.table
    timestamp = table.created_at
    color = @color
    obj = self
    @docx.p
    @docx.table JSON.parse(table.contents_utf_8)['data'], border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE do
      JSON.parse(table.metadata)['cells'].each do |cell|
        cell_style rows[cell['row']][cell['col']], align: obj.table_cell_alignment(cell['className'])
      end
    end
    @docx.p do
      text result.name, italic: true
      text "  #{I18n.t('search.index.archived')} ", bold: true if result.archived?
      text ' '
      text I18n.t 'projects.reports.elements.result_table.table_name', name: table.name
      text ' '
      text I18n.t('projects.reports.elements.result_text.user_time',
                  timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: color[:gray]
    end

    draw_result_comments(result) if @settings.dig('task', 'result_comments')
  end
end
