# frozen_string_literal: true

# handles the import of repository records
# requires 4 parameters:
# @sheet: the csv file with imported rows
# @mappings: mappings for columns
# @user: current_user
# @repository: the repository in which we import the items
module RepositoryImportParser
  class Importer
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
      @mappings.each.with_index do |(_, value), index|
        if value == '-1'
          # Fill blank space, so our indices stay the same
          @columns << nil
          @name_index = index
        else
          @columns << @repository_columns.find_by_id(value)
        end
      end
    end

    def check_for_duplicate_columns
      col_compact = @columns.compact
      if col_compact.map(&:id).uniq.length != col_compact.length
        return { status: :error,
                 nr_of_added: @new_rows_added,
                 total_nr: @total_new_rows }
      end
    end

    def import_rows!
      errors = false
      column_items = []
      @rows.each do |row|
        # Skip empty rows
        next if row.empty?
        unless @header_skipped
          @header_skipped = true
          next
        end
        @total_new_rows += 1

        row = SpreadsheetParser.parse_row(row, @sheet)
        record_row = new_repository_row(row)
        record_row.transaction do
          unless record_row.save
            errors = true
            raise ActiveRecord::Rollback
          end

          row_cell_values = []
          row.each.with_index do |value, index|
            column = @columns[index]
            size = 0
            if column && value.present?
              if column.data_type == 'RepositoryListValue'
                current_items_column = get_items_column(column_items, column)
                size = current_items_column.list_items_number
              end
              # uses RepositoryCellValueResolver to retrieve the correct value
              cell_value_resolver =
                RepositoryImportParser::RepositoryCellValueResolver.new(
                  column,
                  @user,
                  @repository,
                  size
                )
              cell_value = cell_value_resolver.get_value(value, record_row)
              if column.data_type == 'RepositoryListValue'
                current_items_column.list_items_number =
                  cell_value_resolver.column_list_items_size
              end
              next if cell_value.nil? # checks the case if we reach items limit
              cell_value.repository_cell.importing = true
              unless cell_value.valid?
                errors = true
                raise ActiveRecord::Rollback
              end
              row_cell_values << cell_value
            end
          end

          unless import_to_database(row_cell_values)
            errors = true
            raise ActiveRecord::Rollback
          end
          @new_rows_added += 1
        end
      end

      if errors
        return { status: :error,
                 nr_of_added: @new_rows_added,
                 total_nr: @total_new_rows }
      end
      { status: :ok, nr_of_added: @new_rows_added, total_nr: @total_new_rows }
    end

    def new_repository_row(row)
      RepositoryRow.new(name: row[@name_index],
                        repository: @repository,
                        created_by: @user,
                        last_modified_by: @user)
    end

    def import_to_database(row_cell_values)
      return false if RepositoryTextValue.import(
        row_cell_values.select { |element| element.is_a? RepositoryTextValue },
        recursive: true,
        validate: false
      ).failed_instances.any?
      return false if RepositoryListValue.import(
        row_cell_values.select { |element| element.is_a? RepositoryListValue },
        recursive: true,
        validate: false
      ).failed_instances.any?
      true
    end

    def get_items_column(list, column)
      current_column = nil
      list.each do |element|
        current_column = element if element.has_column? column
      end
      unless current_column
        new_column = RepositoryImportParser::ListItemsColumn.new(
          column,
          column.repository_list_items.size
        )
        list << new_column
        return new_column
      end
      current_column
    end
  end
end
