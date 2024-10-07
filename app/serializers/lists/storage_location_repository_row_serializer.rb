# frozen_string_literal: true

module Lists
  class StorageLocationRepositoryRowSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    attributes :created_by, :created_on, :position, :row_id, :row_name, :hidden, :position_formatted, :stock,
               :has_reminder, :reminders_url, :row_url, :row_code

    def row_id
      object.repository_row.id
    end

    def row_code
      object.repository_row.code
    end

    def row_name
      object.repository_row.name unless hidden
    end

    def created_by
      object.created_by.full_name unless hidden
    end

    def created_on
      I18n.l(object.created_at, format: :full) unless hidden
    end

    def position
      object.metadata['position']
    end

    def position_formatted
      "#{('A'..'Z').to_a[position[0] - 1]}#{position[1]}" if position
    end

    def stock
      if !hidden && object.repository_row.repository.has_stock_management?
        object.repository_row.repository_cells.find_by(value_type: 'RepositoryStockValue')&.value&.formatted
      end
    end

    def row_url
      repository_repository_row_path(object.repository_row.repository, object.repository_row)
    end

    def hidden
      return @hidden unless @hidden.nil?

      @hidden = !can_read_repository?(object.repository_row.repository)
    end

    def has_reminder
      object.repository_row.repository_cells.with_active_reminder(scope).any? unless hidden
    end

    def reminders_url
      row = object.repository_row
      active_reminder_repository_cells_repository_repository_row_url(row.repository, row)
    end
  end
end
