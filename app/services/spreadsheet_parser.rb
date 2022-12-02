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

  def self.first_two_rows(sheet, date_format: nil)
    rows = spreadsheet_enumerator(sheet)
    header = []
    columns = []
    rows.take(2).each_with_index do |row_values, i|
      row = parse_row(row_values, sheet, header: i.zero?, date_format: date_format)
      if row && i.zero?
        header = row
      else
        columns = row
      end
    end

    return header, columns
  end

  def self.parse_row(row, sheet, header: false, date_format: nil)
    if sheet.is_a?(Roo::Excelx) && !header
      row.map do |cell|
        if cell.is_a?(Roo::Excelx::Cell::Number) && cell.format == 'General'
          cell&.value&.to_d
        elsif date_format && cell&.value.is_a?(Date)
          cell&.value&.strftime(date_format)
        else
          cell&.formatted_value
        end
      end
    else
      row.map(&:to_s)
    end
  end
end
