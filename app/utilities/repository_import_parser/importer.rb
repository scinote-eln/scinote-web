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

    def initialize(sheet, mappings, user, repository, can_edit_existing_items, should_overwrite_with_empty_cells, preview)
      @columns = []
      @name_index = -1
      @id_index = nil
      @total_new_rows = 0
      @new_rows_added = 0
      @header_skipped = false
      @repository = repository
      @sheet = sheet
      @rows = SpreadsheetParser.spreadsheet_enumerator(@sheet)
      @mappings = mappings
      @user = user
      @repository_columns = @repository.repository_columns
      @can_edit_existing_items = true # can_edit_existing_items
      @should_overwrite_with_empty_cells = true # should_overwrite_with_empty_cells
      @preview = preview
    end

    def run
      fetch_columns
      return check_for_duplicate_columns if check_for_duplicate_columns

      import_rows!
    end

    private

    def fetch_columns
      @mappings.each_with_index do |(_, value), index|
        value = value.to_s unless value.is_a?(Hash)

        case value
        when '0'
          @columns << nil
          @id_index = index
        when '-1'
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

    def handle_invalid_cell_value(value, cell_value)
      if value.present? && cell_value.nil?
        @errors << 'Incorrect data format'
        true
      else
        false
      end
    end

    def import_rows!
      checked_rows = []
      duplicate_ids = SpreadsheetParser.duplicate_ids(@sheet)

      @rows.each do |row|
        next if row.blank?

        unless @header_skipped
          @header_skipped = true
          next
        end
        @total_new_rows += 1
        incoming_row = SpreadsheetParser.parse_row(row, @sheet, date_format: @user.settings['date_format'])
        if @id_index
          existing_row = RepositoryRow.includes(repository_cells: :value)
                                      .find_by(id: incoming_row[@id_index].to_s.gsub(RepositoryRow::ID_PREFIX, ''))
        end

        if existing_row.present?
          if !@can_edit_existing_items
            existing_row.import_status = 'unchanged'
          elsif existing_row.archived
            existing_row.import_status = 'archived'
          elsif existing_row.repository_id != @repository.id
            existing_row.import_status = 'invalid'
            existing_row.import_message = 'Item belongs to another repository'
          elsif duplicate_ids.include?(existing_row.id)
            existing_row.import_status = 'duplicated'
          end

          if existing_row.import_status.present?
            checked_rows << existing_row if @preview
            next
          end
        end

        checked_rows << import_row(existing_row, incoming_row)
      end
<<<<<<< HEAD
      p checked_rows
=======
>>>>>>> b344c5772 (Fix repository import mapping and preview [SCI-10773])
      changes = ActiveModelSerializers::SerializableResource.new(
        checked_rows.compact,
        each_serializer: RepositoryRowImportSerializer,
        include: [:repository_cells]
      ).as_json

      p changes

      { status: :ok, nr_of_added: @new_rows_added, total_nr: @total_new_rows, changes: changes,
        import_date: I18n.l(Date.today, format: :full_date) }
    end

    def import_row(repository_row, import_row)
      @repository.transaction do
        @errors = []
        @updated = false
        repository_row_name = try_decimal_to_string(import_row[@name_index])
        if repository_row.present?
          repository_row.name = repository_row_name
        else
          repository_row = RepositoryRow.new(name: repository_row_name,
                                             repository: @repository,
                                             created_by: @user,
                                             last_modified_by: @user,
                                             import_status: 'created')
        end

        if @preview
          repository_row.validate
          repository_row.id ||= SecureRandom.uuid # ID required for preview with serializer
        else
          repository_row.save!
        end
        @errors << repository_row.errors.full_messages.join(',') if repository_row.errors.present?

        @updated = repository_row.changed?

        @columns.each_with_index do |column, index|
          next if column.blank?

          value = import_row[index]
          value = try_decimal_to_string(value) unless column.repository_number_value?

          cell_value = if value.present?
                         column.data_type.constantize.import_from_text(
                           value,
                           {
                             created_by: @user,
                             last_modified_by: @user,
                             repository_cell_attributes: {
                               repository_row: repository_row,
                               repository_column: column,
                               importing: true
                             }
                           },
                           @user.as_json(root: true, only: :settings).deep_symbolize_keys
                         )
                       end
          next if handle_invalid_cell_value(value, cell_value)

          existing_cell = repository_row.repository_cells.find { |c| c.repository_column_id == column.id }

          existing_cell = if cell_value.nil?
                            handle_nil_cell_value(existing_cell)
                          else
                            handle_existing_cell_value(existing_cell, cell_value, repository_row)
                          end

          @updated ||= existing_cell&.value&.changed?
          @errors << existing_cell.value.errors.full_messages.join(',') if existing_cell&.value&.errors.present?
        end
        repository_row.import_status = if @errors.present?
                                         'invalid'
                                       elsif repository_row.import_status == 'created'
                                         @new_rows_added += 1
                                         'created'
                                       elsif @updated
                                         @new_rows_added += 1
                                         'updated'
                                       else
                                         'unchanged'
                                       end
        repository_row.import_message = @errors.join(',') if @errors.present?
        repository_row
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end

    def handle_nil_cell_value(repository_cell)
      return unless repository_cell.present? && @should_overwrite_with_empty_cells

      if @preview
        repository_cell = nil
        @updated = true
      else
        repository_cell.value.destroy!
      end

      repository_cell
    end

    def handle_existing_cell_value(repository_cell, cell_value, repository_row)
      if repository_cell.present?
        case cell_value
        when RepositoryStockValue
          repository_cell.value.update_data!(cell_value, @user, preview: @preview)
        when RepositoryListValue
          repository_list_item_id = cell_value[:repository_list_item_id]
          repository_cell.value.update_data!(repository_list_item_id, @user, preview: @preview)
        when RepositoryStatusValue
          repository_status_item_id = cell_value[:repository_status_item_id]
          repository_cell.value.update_data!(repository_status_item_id, @user, preview: @preview)
        else
          sanitized_cell_value_data = sanitize_cell_value_data(cell_value.data)
          repository_cell.value.update_data!(sanitized_cell_value_data, @user, preview: @preview)
        end
        repository_cell
      else
        # Create new cell
        cell_value.repository_cell.value = cell_value
        repository_row.repository_cells << cell_value.repository_cell
        @preview ? cell_value.validate : cell_value.save!
        @updated ||= true
        cell_value.repository_cell
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
