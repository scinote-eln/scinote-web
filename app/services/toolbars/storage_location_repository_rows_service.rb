# frozen_string_literal: true

module Toolbars
  class StorageLocationRepositoryRowsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, items_ids: [])
      @current_user = current_user
      @assigned_rows = StorageLocationRepositoryRow.where(id: items_ids)
      @storage_location = @assigned_rows.first&.storage_location

      @single = @assigned_rows.length == 1
    end

    def actions
      return [] if @assigned_rows.none?

      [
        unassign_action,
        move_action
      ].compact
    end

    private

    def unassign_action
      return unless can_manage_storage_location?(@storage_location)

      {
        name: 'unassign',
        label: I18n.t('storage_locations.show.toolbar.unassign'),
        icon: 'sn-icon sn-icon-close',
        path: unassign_rows_storage_location_path(@storage_location, ids: @assigned_rows.pluck(:id)),
        type: :emit
      }
    end

    def move_action
      return unless @single && can_manage_storage_location?(@storage_location)

      {
        name: 'move',
        label: I18n.t('storage_locations.show.toolbar.move'),
        icon: 'sn-icon sn-icon-move',
        path: move_storage_location_storage_location_repository_row_path(
          @storage_location, @assigned_rows.first
        ),
        type: :emit
      }
    end
  end
end
