# frozen_string_literal: true

module ImportRepository
  class ImportRecords
    def initialize(options)
      @temp_file = options.fetch(:temp_file)
      @repository = options.fetch(:repository)
      @mappings = options.fetch(:mappings)
      @session = options.fetch(:session)
      @user = options.fetch(:user)
      @can_edit_existing_items = options.fetch(:can_edit_existing_items)
      @should_overwrite_with_empty_cells = options.fetch(:should_overwrite_with_empty_cells)
      @preview = options.fetch(:preview)
    end

    def import!
      status = @temp_file.file.open do |temp_file|
        importer = RepositoryImportParser::Importer.new(SpreadsheetParser.open_spreadsheet(temp_file),
                                                        @mappings,
                                                        @user,
                                                        @repository,
                                                        @can_edit_existing_items,
                                                        @should_overwrite_with_empty_cells,
                                                        @preview)
        importer.run
      end

      @temp_file.destroy unless @preview
      status
    end
  end
end
