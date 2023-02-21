# frozen_string_literal: true

module ImportRepository
  class ParseRepository
    include ActionView::Helpers::TextHelper
    def initialize(options)
      @file = options.fetch(:file)
      @date_format = options[:date_format]
      @repository = options.fetch(:repository)
      @session = options.fetch(:session)
      @sheet = SpreadsheetParser.open_spreadsheet(@file)
    end

    def data
      header, columns = SpreadsheetParser.first_two_rows(@sheet, date_format: @date_format)
      # Fill in fields for dropdown
      @repository.importable_repository_fields.transform_values! do |name|
        truncate(name, length: Constants::NAME_TRUNCATION_LENGTH_DROPDOWN)
      end
      Data.new(header,
               columns,
               @repository.importable_repository_fields,
               @repository)
    end

    def too_large?
      @file.size > Rails.configuration.x.file_max_size_mb.megabytes
    end

    def has_too_many_rows?
      @sheet.last_row > Constants::IMPORT_REPOSITORY_ITEMS_LIMIT
    end

    def generate_temp_file
      # Save file for next step (importing)
      temp_file = TempFile.new(
        session_id: @session.id,
        file: @file
      )

      if temp_file.save
        TempFile.destroy_obsolete(temp_file.id)
        return temp_file
      end
    end

    Data = Struct.new(
      :header, :columns, :available_fields, :repository
    )
  end
end
