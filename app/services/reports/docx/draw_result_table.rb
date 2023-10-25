# frozen_string_literal: true

module Reports::Docx::DrawResultTable
  def draw_result_table(element)
    result = element.result
    table = element.orderable.table
    timestamp = table.created_at
    color = @color
    obj = self
    table_data = JSON.parse(table.contents_utf_8)['data']
    table_data = obj.add_headers_to_table(table_data, table.metadata.dig('plateTemplate'))

    if table.metadata.present? && table.metadata['cells'].is_a?(Array)
      table.metadata['cells'].each do |cell|
        next unless cell['row'].present? && cell['col'].present?

        row_index = cell['row'].to_i + 1
        col_index = cell['col'].to_i + 1
        calculated_value = cell['calculated']

        if calculated_value.present?
          table_data[row_index][col_index] = calculated_value
        end
      end
    end
    @docx.p
    @docx.table table_data, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE do
      cell_style rows[0], bold: true, background: color[:concrete]
      cell_style cols[0], bold: true, background: color[:concrete]

      if table.metadata.present? && table.metadata['cells'].is_a?(Array)
        table.metadata['cells'].each do |cell|
          next unless cell.present? && cell['row'].present? && cell['col'].present? && cell['className'].present?

          cell_style rows.dig(cell['row'].to_i + 1, cell['col'].to_i + 1),
                     align: obj.table_cell_alignment(cell['className'])
        end
      end
    end
    @docx.p do
      text I18n.t 'projects.reports.elements.result_table.table_name', name: table.name
      text ' '
      text I18n.t('projects.reports.elements.result_table.user_time',
                  timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: color[:gray]
    end
  end
end
