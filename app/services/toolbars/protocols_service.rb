# frozen_string_literal: true

module Toolbars
  class ProtocolsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::AssetUrlHelper

    def initialize(current_user, protocol_ids: [])
      @current_user = current_user
      @protocols = Protocol.where(id: protocol_ids)

      @single = @protocols.length == 1
    end

    def actions
      return [] if @protocols.none?

      [
        restore_action,
        versions_action,
        duplicate_action,
        access_action,
        export_action,
        archive_action
      ].compact
    end

    private

    def versions_action
      return unless @single

      return unless can_read_protocol_in_repository?(@protocols.first)

      {
        name: 'versions',
        label: I18n.t('protocols.index.toolbar.versions'),
        icon: 'sn-icon sn-icon-versions',
        type: :emit
      }
    end

    def duplicate_action
      return unless @single

      protocol = @protocols.first.latest_published_version_or_self
      return unless can_clone_protocol_in_repository?(protocol)

      {
        name: 'duplicate',
        label: I18n.t('protocols.index.toolbar.duplicate'),
        icon: 'sn-icon sn-icon-duplicate',
        path: clone_protocols_path,
        type: :emit
      }
    end

    def access_action
      return unless @single

      {
        name: 'access',
        label: I18n.t('protocols.index.toolbar.access'),
        icon: 'sn-icon sn-icon-project-member-access',
        type: :emit
      }
    end

    def export_action
      return unless @single

      return unless can_read_protocol_in_repository?(@protocols.first)

      {
        name: 'export',
        label: I18n.t('protocols.index.toolbar.export'),
        icon: 'sn-icon sn-icon-export',
        path: export_protocols_path(protocol_ids: @protocols.pluck(:id)),
        type: :emit
      }
    end

    def archive_action
      return unless @protocols.all? { |p| can_archive_protocol_in_repository?(p) }

      {
        name: 'archive',
        label: I18n.t('protocols.index.toolbar.archive'),
        icon: 'sn-icon sn-icon-archive',
        path: archive_protocols_path,
        type: :emit
      }
    end

    def restore_action
      return unless @protocols.all? { |p| can_restore_protocol_in_repository?(p) }

      {
        name: 'restore',
        label: I18n.t('protocols.index.toolbar.restore'),
        icon: 'sn-icon sn-icon-restore',
        path: restore_protocols_path,
        type: :emit
      }
    end
  end
end
