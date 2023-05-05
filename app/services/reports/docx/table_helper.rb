# frozen_string_literal: true

module Reports
  class Docx
    module TableHelper
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
        table.each_with_index do |row, index|
          row.unshift(is_well_plate ? convert_index_to_letter(index) : index + 1)
        end

        header_row = Array.new(table.first.length) do |index|
          if index.zero?
            ''
          else
            is_well_plate ? index : convert_index_to_letter(index - 1)
          end
        end
        table.unshift(header_row)
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
