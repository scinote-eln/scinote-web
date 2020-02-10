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
      @rows.each do |row|
        # Skip empty rows
        next if row.empty?

        unless @header_skipped
          @header_skipped = true
          next
        end
        @total_new_rows += 1

        row = SpreadsheetParser.parse_row(row, @sheet)
        repository_row = new_repository_row(row)
        repository_row.transaction do
          unless repository_row.save
            errors = true
            Rails.logger.error cell_value.errors.full_messages
            raise ActiveRecord::Rollback
          end

          row_cell_values = []
          row.each.with_index do |value, index|
            column = @columns[index]
            if column && value.present?
              attributes = { created_by: @user,
                             last_modified_by: @user,
                             repository_cell_attributes: { repository_row: repository_row,
                                                           repository_column: column,
                                                           importing: true } }

              cell_value = column.data_type.constantize.import_from_text(value, attributes)
              next if cell_value.nil?

              cell_value.repository_cell.value = cell_value

              unless cell_value.valid?
                errors = true
                Rails.logger.error cell_value.errors.full_messages
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
      Extends::REPOSITORY_IMPORTABLE_TYPES.each do |data_type|
        value_class = data_type.to_s.constantize
        values = row_cell_values.select { |v| v.is_a? value_class }
        next if values.blank?

        return false if value_class.import(values, recursive: true, validate: false).failed_instances.any?
      end

      true
    end
  end
end
