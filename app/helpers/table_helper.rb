# frozen_string_literal: true

module TableHelper
  def table_data
    content = {}
    data = JSON.parse(contents)['data']
    return {} if data.blank?

    cells = metadata.fetch('cells', [])

    # Convert legacy table format
    cells = cells.values if cells.is_a?(Hash)

    cells.each do |cell|
      next unless cell['calculated']

      data[cell['row']][cell['col']] = cell['calculated']
    end

    content[:contents] = data
    content[:rows_size] = row_sizes(data)
    content[:columns_size] = column_sizes(data)
    content[:cells_attributes] = cells_attributes(data)
    content[:columns_title] = columns_title(data)
    content[:rows_title] = rows_title(data)
    content
  end

  def row_sizes(data)
    Array.new(data.length, 27)
  end

  def column_sizes(data)
    Array.new(data[0].length, 100)
  end

  def rows_title(data)
    (0...data.length).map do |row_index|
      well_plate? ? convert_index_to_letter(row_index) : row_index + 1
    end
  end

  def columns_title(data)
    (0...data[0].length).map do |col_index|
      well_plate? ? col_index + 1 : convert_index_to_letter(col_index)
    end
  end

  def cells_attributes(_)
    {}
  end

  def convert_index_to_letter(index)
    column_name = ''

    while index >= 0
      column_name = ((index % 26) + 'A'.ord).chr + column_name
      index = (index / 26) - 1
    end

    column_name
  end
end
