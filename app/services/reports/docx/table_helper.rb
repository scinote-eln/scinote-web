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
    end
  end
end
