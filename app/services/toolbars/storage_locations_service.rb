# frozen_string_literal: true

module Toolbars
  class StorageLocationsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(storage_locations, current_user)
      @storage_locations = storage_locations
      @current_user = current_user

      @single = @storage_locations.length == 1
    end

    def actions
      return [] if @storage_locations.none?

      [
        edit_action,
        move_action,
        duplicate_action,
        delete_action,
        share_action
      ].compact
    end

    private

    def edit_action
      return unless @single && can_manage_storage_location?(@storage_locations.first)

      {
        name: 'edit',
        label: I18n.t('storage_locations.index.toolbar.edit'),
        icon: 'sn-icon sn-icon-edit',
        path: storage_location_path(@storage_locations.first),
        type: :emit
      }
    end

    def move_action
      return unless @single && can_manage_storage_location?(@storage_locations.first)

      {
        name: 'move',
        label: I18n.t('storage_locations.index.toolbar.move'),
        icon: 'sn-icon sn-icon-move',
        path: move_storage_location_path(@storage_locations.first),
        type: :emit
      }
    end

    def duplicate_action
      return unless @single && can_manage_storage_location?(@storage_locations.first)

      {
        name: 'duplicate',
        label: I18n.t('storage_locations.index.toolbar.duplicate'),
        icon: 'sn-icon sn-icon-duplicate',
        path: duplicate_storage_location_path(@storage_locations.first),
        type: :emit
      }
    end

    def delete_action
      return unless @single && can_manage_storage_location?(@storage_locations.first)

      storage_location = @storage_locations.first

      number_of_items = storage_location.storage_location_repository_rows.count +
                        StorageLocation.inner_storage_locations(storage_location)
                                       .where(container: true)
                                       .joins(:storage_location_repository_rows)
                                       .count
      {
        name: 'delete',
        label: I18n.t('storage_locations.index.toolbar.delete'),
        icon: 'sn-icon sn-icon-delete',
        number_of_items: number_of_items,
        path: storage_location_path(storage_location),
        type: :emit
      }
    end

    def share_action
      return unless @single && can_share_storage_location?(@storage_locations.first)

      {
        name: :share,
        label: I18n.t('storage_locations.index.share'),
        icon: 'sn-icon sn-icon-shared',
        type: :emit
      }
    end
  end
end
