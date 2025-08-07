# frozen_string_literal: true

module Reports
  class Docx
    module TableHelper
      def render_table(table, table_type, color)
        table_data = JSON.parse(table.contents_utf_8)['data']
        table_data = add_headers_to_table(table_data, table_type == 'well_plates_table')

        if table.metadata.present? && table.metadata['cells'].is_a?(Array)
          table.metadata&.dig('cells')&.each do |cell|
            next unless cell.is_a?(Hash)
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

        return unless table_data.present? && table_data[0].present?

        @docx.table table_data, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE do
          cell_style rows[0], bold: true, background: color[:concrete]
          cell_style cols[0], bold: true, background: color[:concrete]

          if table.metadata.present? && table.metadata['cells'].is_a?(Array)
            table.metadata['cells'].each do |cell|
              data = cell[1]
              next unless data.present? && data['row'].present? && data['col'].present? && data['className'].present?

              cell_style rows.dig(data['row'].to_i + 1, data['col'].to_i + 1),
                        align: table_cell_alignment(data['className'])
            end
          end
        end
      end

      def table_cell_alignment(cell_class)
        if cell_class.include?('htCenter')
          :center
        elsif cell_class.include?('htRight')
          :right
        elsif cell_class.include?('htJustify')
          :both
        else
          :left
        end
      end

      def add_headers_to_table(table, is_well_plate)
        table&.each_with_index do |row, index|
          row.unshift(is_well_plate ? convert_index_to_letter(index) : index + 1)
        end

        header_row = Array.new(table&.dig(0)&.length || 0) do |index|
          next '' if index.zero?

          is_well_plate ? index : convert_index_to_letter(index - 1)
        end
        table&.unshift(header_row)
      end

      def convert_index_to_letter(index)
        ord_a = 'A'.ord
        ord_z = 'Z'.ord
        len = (ord_z - ord_a) + 1
        num = index

        col_name = ''
        while num >= 0
          col_name = ((num % len) + ord_a).chr + col_name
          num = (num / len).floor - 1
        end
        col_name
      end
    end
  end
end
