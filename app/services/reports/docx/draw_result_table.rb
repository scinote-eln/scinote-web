# frozen_string_literal: true

module Reports::Docx::DrawResultTable
  def draw_result_table(result)
    table = result.table
    timestamp = table.created_at
    color = @color
    obj = self
    table_data = JSON.parse(table.contents_utf_8)['data']
    table_data = obj.add_headers_to_table(table_data, false)
    @docx.p
    @docx.table table_data, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE do
      cell_style rows[0], bold: true, background: color[:concrete]
      cell_style cols[0], bold: true, background: color[:concrete]

      if table.metadata.present?
        JSON.parse(table.metadata)['cells']&.each do |cell|
          next unless cell.present? && cell['row'].present? && cell['col'].present? && cell['className'].present?

          cell_style rows.dig(cell['row'].to_i + 1, cell['col'].to_i + 1),
                     align: obj.table_cell_alignment(cell['className'])
        end
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
