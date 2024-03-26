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

    def run(can_edit_existing_items, should_overwrite_with_empty_cells)
      fetch_columns
      return check_for_duplicate_columns if check_for_duplicate_columns

      import_rows!(can_edit_existing_items, should_overwrite_with_empty_cells)
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

    def import_rows!(can_edit_existing_items, should_overwrite_with_empty_cells)
      errors = false
      duplicate_ids = SpreadsheetParser.duplicate_ids(@sheet)

      @repository.transaction do
        batch_counter = 0
        full_row_import_batch = []

        @rows.each do |row|
          # Skip empty rows
          next if row.blank?

          # Skip duplicates
          next if duplicate_ids.include?(row.first)

          unless @header_skipped
            @header_skipped = true
            next
          end
          @total_new_rows += 1

          new_full_row = {}
          incoming_row = SpreadsheetParser.parse_row(
            row,
            @sheet,
            date_format: @user.settings['date_format']
          )

          incoming_row.each_with_index do |value, index|
            if index == @name_index

              # check if row (inventory) already exists
              existing_row = RepositoryRow.find_by(id: incoming_row[0])

              # if it doesn't exist create it
              unless existing_row
                new_row =
                RepositoryRow.new(name: try_decimal_to_string(value),
                                  repository: @repository,
                                  created_by: @user,
                                  last_modified_by: @user)
                unless new_row.valid?
                  errors = true
                  break
                end
                new_full_row[:repository_row] = new_row
                next
              end

              # if it does exist but shouldn't be edited, error out and break
              if existing_row && can_edit_existing_items == '0'
                errors = true
                break
              end

              # if it does exist and should be edited, update the existing row
              if existing_row && can_edit_existing_items == '1'
                # update the existing row with incoming row data
                new_full_row[:repository_row] = existing_row
              end
            end

            next unless @columns[index]
            new_full_row[index] = value
          end

          if new_full_row[:repository_row].present?
            full_row_import_batch << new_full_row
            batch_counter += 1
          end

          next if batch_counter < IMPORT_BATCH_SIZE

          import_batch_to_database(full_row_import_batch, can_edit_existing_items, should_overwrite_with_empty_cells)
          full_row_import_batch = []
          batch_counter = 0
        end

        # Import of the remaining rows
        import_batch_to_database(full_row_import_batch, can_edit_existing_items, should_overwrite_with_empty_cells) if full_row_import_batch.any?
      end

      if errors
        return { status: :error,
                 nr_of_added: @new_rows_added,
                 total_nr: @total_new_rows }
      end
      { status: :ok, nr_of_added: @new_rows_added, total_nr: @total_new_rows }
    end

    def import_batch_to_database(full_row_import_batch, can_edit_existing_items, should_overwrite_with_empty_cells)
      skipped_rows = []

      full_row_import_batch.each do |full_row|
        # skip archived rows and rows that belong to other repositories
        if full_row[:repository_row].archived || full_row[:repository_row].repository_id != @repository.id
          skipped_rows << full_row[:repository_row]
          next
        end

        full_row[:repository_row].save!(validate: false)
        @new_rows_added += 1

        full_row.reject { |k| k == :repository_row }.each do |index, value|
          column = @columns[index]
          value = try_decimal_to_string(value) unless column.repository_number_value?
          next if value.nil?

          cell_value_attributes = {
            created_by: @user,
            last_modified_by: @user,
            repository_cell_attributes: {
              repository_row: full_row[:repository_row],
              repository_column: column,
              importing: true
            }
          }

          cell_value = column.data_type.constantize.import_from_text(
            value,
            cell_value_attributes,
            @user.as_json(root: true, only: :settings).deep_symbolize_keys
          )

          existing_cell = full_row[:repository_row].repository_cells.find_by(repository_column: column)

          next if cell_value.nil? && existing_cell.nil?

          # no existing_cell. Create a new one.
          if !existing_cell
            cell_value.repository_cell.value = cell_value
            cell_value.save!(validate: false)
          else
            # existing_cell present && !can_edit_existing_items
            next if can_edit_existing_items == '0'

            # existing_cell present && can_edit_existing_items
            if can_edit_existing_items == '1'
              # if incoming cell is not empty
              existing_cell.value.update_data!(cell_value.data, @user) if !cell_value.nil?

              # if incoming cell is empty && should_overwrite_with_empty_cells
              existing_cell.value.destroy! if cell_value.nil? && should_overwrite_with_empty_cells == '1'

              # if incoming cell is empty && !should_overwrite_with_empty_cells
              next if cell_value.nil? && should_overwrite_with_empty_cells == '0'
            end
          end
        end
      end
    end

    def try_decimal_to_string(value)
      if value.is_a?(BigDecimal)
        value.frac.zero? ? value.to_i.to_s : value.to_s
      else
        value
      end
    end
  end
end
