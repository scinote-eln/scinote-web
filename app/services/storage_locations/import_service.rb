# frozen_string_literal: true

require 'caxlsx'

module StorageLocations
  class ImportService
    class PositionNotValid < StandardError; end

    def initialize(storage_location, file, user)
      @storage_location = storage_location
      @assigned_count = 0
      @unassigned_count = 0
      @sheet = SpreadsheetParser.open_spreadsheet(file)
      @user = user
    end

    def import_items
      @rows = SpreadsheetParser.spreadsheet_enumerator(@sheet).reject { |r| r.all?(&:blank?) }

      # Check if the file has proper headers
      header = SpreadsheetParser.parse_row(@rows[0], @sheet)
      return { status: :error, message: I18n.t('storage_locations.show.import_modal.errors.invalid_structure') } unless header[0] == 'Box position' && header[1] == 'Item ID'

      parse_rows!

      # Check duplicate positions in the file
      if @storage_location.with_grid? && @rows.pluck(:position).uniq.length != @rows.length
        return { status: :error, message: I18n.t('storage_locations.show.import_modal.errors.invalid_position') }
      end

      # Check if duplicate repository rows are present in the file
      if !@storage_location.with_grid? && @rows.pluck(:repository_row_id).uniq.length != @rows.length
        return { status: :error, message: I18n.t('storage_locations.show.import_modal.errors.duplicate_items') }
      end

      ActiveRecord::Base.transaction do
        unassign_repository_rows! if @storage_location.with_grid?

        @rows.each do |row|
          next if row[:repository_row_id].blank?

          if @storage_location.with_grid? && !position_valid?(row[:position])
            @error_message = I18n.t('storage_locations.show.import_modal.errors.invalid_position')
            raise ActiveRecord::RecordInvalid
          end

          unless RepositoryRow.exists?(id: row[:repository_row_id], parent_id: nil)
            @error_message = I18n.t('storage_locations.show.import_modal.errors.invalid_item', row_id: row[:repository_row_id])
            raise ActiveRecord::RecordNotFound
          end

          import_row!(row)
        end
      end

      { status: :ok, assigned_count: @assigned_count, unassigned_count: @unassigned_count, updated_count: @updated_count }
    rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid
      { status: :error, message: @error_message }
    rescue PositionNotValid
      { status: :error, message: I18n.t('storage_locations.show.import_modal.errors.invalid_position') }
    end

    private

    def parse_rows!
      # Remove first row
      @rows.shift

      @rows.map! do |r|
        row = SpreadsheetParser.parse_row(r, @sheet)
        {
          position: convert_position_letter_to_number(row[0]),
          repository_row_id: (row[1].to_s.gsub('IT', '') if row[1].present?)
        }
      end
    end

    def import_row!(row)
      storage_location_repository_row = if @storage_location.with_grid?
                                          @storage_location.storage_location_repository_rows
                                                           .find_or_initialize_by(
                                                             repository_row_id: row[:repository_row_id],
                                                             metadata: { position: row[:position] }
                                                           )
                                        else
                                          @storage_location.storage_location_repository_rows
                                                           .find_or_initialize_by(repository_row_id: row[:repository_row_id])
                                        end

      if storage_location_repository_row.new_record?
        @assigned_count += 1
        storage_location_repository_row.update!(created_by: @user)
      end
    end

    def unassign_repository_rows!
      @storage_location.storage_location_repository_rows.each do |s|
        if @rows.exclude?({ position: s.metadata['position'], repository_row_id: s.repository_row_id })
          @unassigned_count += 1
          s.discard
        end
      end
    end

    def position_valid?(position)
      position[0].to_i <= @storage_location.grid_size[0].to_i && position[1].to_i <= @storage_location.grid_size[1].to_i
    end

    def convert_position_letter_to_number(position)
      return unless position

      raise PositionNotValid unless position.to_s.match?(/^[A-Z]\d+$/)

      column_letter = position[0]
      row_number = position[1..]

      [column_letter.ord - 64, row_number.to_i]
    end
  end
end
