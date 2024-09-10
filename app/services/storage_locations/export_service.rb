# frozen_string_literal: true

require 'caxlsx'

module StorageLocations
  class ExportService
    include Canaid::Helpers::PermissionsHelper
    def initialize(storage_location, user)
      @storage_location = storage_location
      @user = user
    end

    def to_xlsx
      package = Axlsx::Package.new
      workbook = package.workbook

      workbook.add_worksheet(name: 'Box Export') do |sheet|
        sheet.add_row ['Box position', 'Item ID', 'Item name']

        @storage_location.storage_location_repository_rows.each do |storage_location_item|
          row = storage_location_item.repository_row
          row_name = row.name if can_read_repository?(@user, row.repository)
          sheet.add_row [format_position(storage_location_item), storage_location_item.repository_row_id, row_name]
        end
      end

      package.to_stream.read
    end

    private

    def format_position(item)
      position = item.metadata['position']

      return unless position

      column_letter = ('A'..'Z').to_a[position[0] - 1]
      row_number = position[1]

      "#{column_letter}#{row_number}"
    end
  end
end
