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
      header = @sheet.row(1)
      columns = @sheet.row(2)
      # Fill in fields for dropdown
      @repository.available_repository_fields.transform_values! do |name|
        truncate(name, length: Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
      end
      @temp_file = TempFile.create(session_id: @session.id, file: @file)
      Data.new(header,
               columns,
               @repository.available_repository_fields,
               @repository,
               @temp_file)
    end

    def too_large?
      @file.size > Constants::FILE_MAX_SIZE_MB.megabytes
    end

    def empty?
      @sheet.last_row.between?(0, 1)
    end

    def generated_temp_file?
      # Save file for next step (importing)
      @temp_file = TempFile.new(
        session_id: @session.id,
        file: @file
      )

      if @temp_file.save
        @temp_file.destroy_obsolete
        return true
      end
    end

    Data = Struct.new(
      :header, :columns, :available_fields, :repository, :temp_file
    )
  end
end
