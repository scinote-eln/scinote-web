# frozen_string_literal: true

class SpreadsheetParser
  # Based on file's extension opens file (used for importing)
  def self.open_spreadsheet(file)
    file_path = file.path
    filename = if file.class.name.split('::')[-1] == 'UploadedFile'
                 file.original_filename
               else
                 File.basename(file.path)
               end

    case File.extname(filename)
    when '.csv'
      Roo::CSV.new(file_path, extension: :csv)
    when '.tsv'
      Roo::CSV.new(file_path, csv_options: { col_sep: "\t" })
    when '.txt'
      # This assumption is based purely on biologist's habits
      Roo::CSV.new(file_path, csv_options: { col_sep: "\t" })
    when '.xlsx'
      Roo::Excelx.new(file_path)
    else
      raise TypeError
    end
  end

  def self.spreadsheet_enumerator(sheet)
    if sheet.is_a?(Roo::CSV)
      sheet
    elsif sheet.is_a?(Roo::Excelx)
      sheet.each_row_streaming(pad_cells: true)
    else
      sheet.rows
    end
  end

  def self.first_two_rows(sheet)
    rows = spreadsheet_enumerator(sheet)
    header = []
    columns = []
    i = 1
    rows.each do |row_values|
      # Creek XLSX parser returns Hash of the row, Roo - Array
      row = parse_row(row_values, sheet)
      header = row if i == 1 && row
      columns = row if i == 2 && row
      i += 1
      break if i > 2
    end
    return header, columns
  end

  def self.parse_row(row, sheet)
    if sheet.is_a?(Roo::Excelx)
      row.map { |cell| cell&.formatted_value }
    else
      row.map(&:to_s)
    end
  end
end
