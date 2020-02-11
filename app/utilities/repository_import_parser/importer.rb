# frozen_string_literal: true

# handles the import of repository records
# requires 4 parameters:
# @sheet: the csv file with imported rows
# @mappings: mappings for columns
# @user: current_user
# @repository: the repository in which we import the items
module RepositoryImportParser
  class Importer
    IMPORT_BATCH_SIZE = 500

    def initialize(sheet, mappings, user, repository)
      @columns = []
      @name_index = -1
      @total_new_rows = 0
      @new_rows_added = 0
      @header_skipped = false
      @repository = repository
      @sheet = sheet
      @rows = SpreadsheetParser.spreadsheet_enumerator(@sheet)
      @mappings = mappings
      @user = user
      @repository_columns = @repository.repository_columns
    end

    def run
      fetch_columns
      return check_for_duplicate_columns if check_for_duplicate_columns

      import_rows!
    end

    private

    def fetch_columns
      @mappings.each_with_index do |(_, value), index|
        if value == '-1'
          # Fill blank space, so our indices stay the same
          @columns << nil
          @name_index = index
        else
          @columns << @repository_columns.where(data_type: Extends::REPOSITORY_IMPORTABLE_TYPES)
                                         .preload(Extends::REPOSITORY_IMPORT_COLUMN_PRELOADS)
                                         .find_by(id: value)
        end
      end
    end

    def check_for_duplicate_columns
      col_compact = @columns.compact
      if col_compact.map(&:id).uniq.length != col_compact.length
        { status: :error, nr_of_added: @new_rows_added, total_nr: @total_new_rows }
      end
    end

    def import_rows!
      errors = false

      @repository.transaction do
        batch_counter = 0
        full_row_import_batch = []

        @rows.each do |row|
          # Skip empty rows
          next if row.empty?

          unless @header_skipped
            @header_skipped = true
            next
          end
          @total_new_rows += 1

          new_full_row = {}
          SpreadsheetParser.parse_row(row, @sheet).each_with_index do |value, index|
            if index == @name_index
              new_row =
                RepositoryRow.new(name: value, repository: @repository, created_by: @user, last_modified_by: @user)
              unless new_row.valid?
                errors = true
                break
              end

              new_full_row[:repository_row] = new_row
              next
            end
            next unless @columns[index]

            new_full_row[index] = value
          end

          if new_full_row[:repository_row].present?
            full_row_import_batch << new_full_row
            batch_counter += 1
          end

          next if batch_counter < IMPORT_BATCH_SIZE

          import_batch_to_database(full_row_import_batch)
          full_row_import_batch = []
          batch_counter = 0
        end

        # Import of the remaining rows
        import_batch_to_database(full_row_import_batch) if full_row_import_batch.any?
      end

      if errors
        return { status: :error,
                 nr_of_added: @new_rows_added,
                 total_nr: @total_new_rows }
      end
      { status: :ok, nr_of_added: @new_rows_added, total_nr: @total_new_rows }
    end

    def import_batch_to_database(full_row_import_batch)
      repository_rows = full_row_import_batch.collect { |row| row[:repository_row] }
      @new_rows_added += RepositoryRow.import(repository_rows, recursive: false, validate: false).ids.length
      repository_rows.each { |row| row.run_callbacks(:create) }

      import_mappings = Hash[@columns.map { |column| column&.data_type&.to_sym }
                                     .compact
                                     .uniq
                                     .map { |data_type| [data_type, []] }]

      full_row_import_batch.each do |row|
        next unless row[:repository_row].id

        row.reject { |k| k == :repository_row }.each do |index, value|
          column = @columns[index]
          cell_value_attributes = { created_by: @user,
                                    last_modified_by: @user,
                                    repository_cell_attributes: { repository_row: row[:repository_row],
                                                                  repository_column: column,
                                                                  importing: true } }

          cell_value = column.data_type.constantize.import_from_text(value, cell_value_attributes)
          next if cell_value.nil?

          cell_value.repository_cell.value = cell_value

          import_mappings[column.data_type.to_sym] << cell_value
        end
      end

      import_mappings.each do |data_type, cell_values|
        data_type.to_s.constantize.import(cell_values, recursive: true, validate: false)
      end
    end
  end
end
