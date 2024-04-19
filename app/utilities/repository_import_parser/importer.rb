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

    def run(can_edit_existing_items, should_overwrite_with_empty_cells, preview)
      fetch_columns
      return check_for_duplicate_columns if check_for_duplicate_columns

      import_rows!(can_edit_existing_items, should_overwrite_with_empty_cells, preview)
    end

    private

    def fetch_columns
      @mappings.each_with_index do |(_, value), index|
        value = JSON.parse(value) rescue value
        value = value.to_s unless value.is_a?(Hash)

        if value == '-1'
          # Fill blank space, so our indices stay the same
          @columns << nil
          @name_index = index

        # creating a custom option column
        elsif value.is_a?(Hash)
          new_repository_column = @repository.repository_columns.create!(created_by: @user, name: value['name']+rand(10000).to_s, data_type: "Repository#{value['type']}Value")
          @columns << new_repository_column
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

    def import_rows!(can_edit_existing_items, should_overwrite_with_empty_cells, preview)
      errors = false
      duplicate_ids = SpreadsheetParser.duplicate_ids(@sheet)

      imported_rows = []

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
              existing_row = RepositoryRow.includes(repository_cells: :value).find_by(id: incoming_row[0].gsub(RepositoryRow::ID_PREFIX, ''))

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

              # if it's a preview always add the existing row
              if preview
                new_full_row[:repository_row] = existing_row

              # otherwise add according to criteria
              else
                # if it does exist but shouldn't be edited, error out and break
                if existing_row && (can_edit_existing_items == false)
                  errors = true
                  break
                end

                # if it does exist and should be edited, update the existing row
                if existing_row && (can_edit_existing_items == true)
                  # update the existing row with incoming row data
                  new_full_row[:repository_row] = existing_row
                end
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

          # import_batch_to_database(full_row_import_batch, can_edit_existing_items, should_overwrite_with_empty_cells, preview: preview)
          imported_rows += import_batch_to_database(full_row_import_batch, can_edit_existing_items, should_overwrite_with_empty_cells, preview)
          full_row_import_batch = []
          batch_counter = 0
        end

        # Import of the remaining rows
        imported_rows += import_batch_to_database(full_row_import_batch, can_edit_existing_items, should_overwrite_with_empty_cells, preview) if full_row_import_batch.any?

        full_row_import_batch
      end

      if errors
        return { status: :error,
                 nr_of_added: @new_rows_added,
                 total_nr: @total_new_rows }
      end
      changes = ActiveModelSerializers::SerializableResource.new(
        imported_rows,
        each_serializer: RepositoryRowSerializer,
        include: [:repository_cells]
      ).as_json[:included]

      { status: :ok, nr_of_added: @new_rows_added, total_nr: @total_new_rows, changes: changes }
    end

    def import_batch_to_database(full_row_import_batch, can_edit_existing_items, should_overwrite_with_empty_cells, preview)
      skipped_rows = []

      full_row_import_batch.map do |full_row|
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

          existing_cell = full_row[:repository_row].repository_cells.find { |c| c.repository_column_id == column.id }

          next if cell_value.nil? && existing_cell.nil?

          if existing_cell
            # existing_cell present && !can_edit_existing_items
            next if can_edit_existing_items == false

            # existing_cell present && can_edit_existing_items
            if can_edit_existing_items == true
              # if incoming cell is not empty
              case cell_value

              when RepositoryStockValue
                existing_cell.value.update_data!(cell_value, @user, preview: preview) unless cell_value.nil?

              when RepositoryListValue
                repository_list_item_id = cell_value[:repository_list_item_id]
                existing_cell.value.update_data!(repository_list_item_id, @user, preview: preview) unless cell_value.nil?

              when RepositoryStatusValue
                repository_status_item_id = cell_value[:repository_status_item_id]
                existing_cell.value.update_data!(repository_status_item_id, @user, preview: preview) unless cell_value.nil?

              else
                sanitized_cell_value_data = sanitize_cell_value_data(cell_value.data)
                existing_cell.value.update_data!(sanitized_cell_value_data, @user, preview: preview) unless cell_value.nil?
              end

              # if incoming cell is empty && should_overwrite_with_empty_cells
              existing_cell.value.destroy! if cell_value.nil? && should_overwrite_with_empty_cells == true

              # if incoming cell is empty && !should_overwrite_with_empty_cells
              next if cell_value.nil? && should_overwrite_with_empty_cells == false
            end
          else
            # no existing_cell. Create a new one.
            cell_value.repository_cell.value = cell_value
            cell_value.save!(validate: false)
          end
        end

        full_row[:repository_row]
      end
    end

    def sanitize_cell_value_data(cell_value_data)
      case cell_value_data
      # when importing from .csv for:
      # repository_text_value, repository_number_value, repository_date_value, repository_date_time_value_base
      when String, Numeric, Date, Time
        cell_value_data
      when Array
        cell_value_data.filter_map do |element|
          if element.is_a?(Hash) && element.key?(:value)
            element[:value].to_s
          elsif element.is_a?(String)
            element
          end
        end
      else
        []
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
