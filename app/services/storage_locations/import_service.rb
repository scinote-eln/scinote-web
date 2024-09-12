# frozen_string_literal: true

require 'caxlsx'

module StorageLocations
  class ImportService
    def initialize(storage_location, file, user)
      @storage_location = storage_location
      @file = file
      @user = user
    end

    def import_items
      sheet = SpreadsheetParser.open_spreadsheet(@file)
      incoming_items = SpreadsheetParser.spreadsheet_enumerator(sheet).reject { |r| r.all?(&:blank?) }

      # Check if the file has proper headers
      header = SpreadsheetParser.parse_row(incoming_items[0], sheet)
      return { status: :error, message: I18n.t('storage_locations.show.import_modal.errors.invalid_structure') } unless header[0] == 'Box position' && header[1] == 'Item ID'

      # Remove first row
      incoming_items.shift

      incoming_items.map! { |r| SpreadsheetParser.parse_row(r, sheet) }

      # Check duplicate positions in the file
      if @storage_location.with_grid? && incoming_items.pluck(0).uniq.length != incoming_items.length
        return { status: :error, message: I18n.t('storage_locations.show.import_modal.errors.invalid_position') }
      end

      existing_items = @storage_location.storage_location_repository_rows.map do |item|
        [convert_position_number_to_letter(item), item.repository_row_id, item.id]
      end

      items_to_unassign = []

      existing_items.each do |existing_item|
        if incoming_items.any? { |r| r[0] == existing_item[0] && r[1].to_i == existing_item[1] }
          incoming_items.reject! { |r| r[0] == existing_item[0] && r[1].to_i == existing_item[1] }
        else
          items_to_unassign << existing_item[2]
        end
      end

      error_message = ''

      ActiveRecord::Base.transaction do
        @storage_location.storage_location_repository_rows.where(id: items_to_unassign).discard_all

        incoming_items.each do |row|
          if @storage_location.with_grid?
            position = convert_position_letter_to_number(row[0])

            unless position[0].to_i <= @storage_location.grid_size[0].to_i && position[1].to_i <= @storage_location.grid_size[1].to_i
              error_message = I18n.t('storage_locations.show.import_modal.errors.invalid_position')
              raise ActiveRecord::RecordInvalid
            end
          end

          repository_row = RepositoryRow.find_by(id: row[1])

          unless repository_row
            error_message = I18n.t('storage_locations.show.import_modal.errors.invalid_item', row_id: row[1].to_i)
            raise ActiveRecord::RecordNotFound
          end

          @storage_location.storage_location_repository_rows.create!(
            repository_row: repository_row,
            metadata: { position: position },
            created_by: @user
          )
        end
      rescue ActiveRecord::RecordNotFound
        return { status: :error, message: error_message }
      end

      { status: :ok }
    end

    private

    def convert_position_letter_to_number(position)
      return unless position

      column_letter = position[0]
      row_number = position[1]

      [column_letter.ord - 64, row_number.to_i]
    end

    def convert_position_number_to_letter(item)
      position = item.metadata['position']

      return unless position

      column_letter = ('A'..'Z').to_a[position[0] - 1]
      row_number = position[1]

      "#{column_letter}#{row_number}"
    end
  end
end
