# frozen_string_literal: true

module Toolbars
  class StorageLocationsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, storage_location_ids: [])
      @current_user = current_user
      @storage_locations = StorageLocation.where(id: storage_location_ids)

      @single = @storage_locations.length == 1
    end

    def actions
      return [] if @storage_locations.none?

      [
        edit_action,
        move_action,
        duplicate_action,
        delete_action
      ].compact
    end

    private

    def edit_action
      return unless @single

      return unless can_manage_storage_locations?(current_user.current_team)

      {
        name: 'edit',
        label: I18n.t('storage_locations.index.toolbar.edit'),
        icon: 'sn-icon sn-icon-edit',
        path: storage_location_path(@storage_locations.first),
        type: :emit
      }
    end

    def move_action
      return unless @single

      return unless can_manage_storage_locations?(current_user.current_team)

      {
        name: 'set_as_default',
        label: I18n.t("storage_locations.index.toolbar.move"),
        icon: 'sn-icon sn-icon-move',
        path: move_storage_location_path(@storage_locations.first),
        type: :emit
      }
    end

    def duplicate_action
      return unless @single

      return unless can_manage_storage_locations?(current_user.current_team)

      {
        name: 'duplicate',
        label: I18n.t('storage_locations.index.toolbar.duplicate'),
        icon: 'sn-icon sn-icon-duplicate',
        path: copy_storage_location_path(@storage_locations.first),
        type: :emit
      }
    end

    def delete_action
      return unless @single

      return unless can_manage_storage_locations?(current_user.current_team)

      {
        name: 'delete',
        label: I18n.t('storage_locations.index.toolbar.delete'),
        icon: 'sn-icon sn-icon-delete',
        path: storage_location_path(@storage_locations.first),
        type: :emit
      }
    end
  end
end
