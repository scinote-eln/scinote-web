module ImportRepository
  class ParseRepository
    include ActionView::Helpers::TextHelper
    def initialize(options)
      @file = options.fetch(:file)
      @repository = options.fetch(:repository)
      @session = options.fetch(:session)
      @sheet = @repository.open_spreadsheet(@file)
    end

    def data
      # Get data (it will trigger any errors as well)
      if @sheet.is_a?(Roo::CSV)
        header = @sheet.row(1)
        columns = @sheet.row(2)
      elsif @sheet.is_a?(Roo::Excelx)
        i = 1
        @sheet.each_row_streaming do |row|
          header = row.map(&:cell_value) if i == 1
          columns = row.map(&:cell_value) if i == 2
          i += 1
          break if i > 2
        end
      else
        i = 1
        @sheet.rows.each do |row|
          header = row.values if i == 1
          columns = row.values if i == 2
          i += 1
          break if i > 2
        end
      end
      # Fill in fields for dropdown
      @repository.available_repository_fields.transform_values! do |name|
        truncate(name, length: Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
      end
      header ||= []
      columns ||= []
      Data.new(header,
               columns,
               @repository.available_repository_fields,
               @repository)
    end

    def too_large?
      @file.size > Constants::FILE_MAX_SIZE_MB.megabytes
    end

    def generate_temp_file
      # Save file for next step (importing)
      temp_file = TempFile.new(
        session_id: @session.id,
        file: @file
      )

      if temp_file.save
        temp_file.destroy_obsolete
        return temp_file
      end
    end

    Data = Struct.new(
      :header, :columns, :available_fields, :repository
    )
  end
end
