# frozen_string_literal: true

module Reports::Docx::DrawStepTable
  def draw_step_table(table, table_type)
    color = @color
    timestamp = table.created_at
    obj = self
    table_data = JSON.parse(table.contents_utf_8)['data']
    table_data = obj.add_headers_to_table(table_data, table_type == 'step_well_plates_table')

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
          data = cell[1]
          next unless data.present? && data['row'].present? && data['col'].present? && data['className'].present?

          cell_style rows.dig(data['row'].to_i + 1, data['col'].to_i + 1),
                     align: obj.table_cell_alignment(data['className'])
        end
      end
    end
    @docx.p do
      text I18n.t("projects.reports.elements.#{table_type}.table_name", name: table.name), italic: true
      text ' '
      text I18n.t("projects.reports.elements.#{table_type}.user_time",
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
  end
end
