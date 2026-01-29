# frozen_string_literal: true

module Toolbars
  class ProtocolRepositoryRowsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, protocol, row_ids: [])
      @current_user = current_user
      @protocol = protocol
      @rows = protocol.protocol_repository_rows.where(id: row_ids)

      @single = @rows.length == 1
    end

    def actions
      return [] if @rows.none?

      [
        delete_action
      ].compact
    end

    private

    def delete_action
      return unless can_manage_protocol_draft_in_repository?(@protocol)

      {
        name: 'delete',
        label: I18n.t('protocols.repository_rows.index.unassign_item'),
        icon: 'sn-icon sn-icon-close',
        path: batch_destroy_protocol_repository_rows_path(@protocol, row_ids: @rows.pluck(:id)),
        type: :emit
      }
    end
  end
end
