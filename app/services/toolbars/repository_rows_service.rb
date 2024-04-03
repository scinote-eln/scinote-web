# frozen_string_literal: true

class RepositoryMismatchError < StandardError; end

module Toolbars
  class RepositoryRowsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, repository_row_ids: [])
      @current_user = current_user
      @repository_rows = RepositoryRow.where(id: repository_row_ids)

      return if @repository_rows.none?

      if @repository_rows.pluck(:repository_id).uniq.size != 1
        raise RepositoryMismatchError, 'Items are not from the same repository!'
      end

      @repository = @repository_rows.first.repository

      @single = @repository_rows.length == 1
    end

    def actions
      return [] if @repository_rows.none?

      [
        restore_action,
        edit_action,
        assign_action,
        duplicate_action,
        export_actions,
        print_label_action,
        archive_action,
        delete_action
      ].compact
    end

    private

    def restore_action
      return unless can_manage_repository_rows?(@repository)

      return unless @repository_rows.all?(&:archived?)

      {
        name: 'restore',
        label: I18n.t('repositories.restore_record'),
        icon: 'sn-icon sn-icon-restore',
        type: :emit
      }
    end

    def edit_action
      return unless can_manage_repository_rows?(@repository)

      return unless @repository_rows.all?(&:active?)

      {
        name: 'edit',
        label: I18n.t('repositories.edit_record'),
        icon: 'sn-icon sn-icon-edit',
        type: :emit
      }
    end

    def assign_action
      return unless can_read_repository?(@repository)

      return unless @repository_rows.all?(&:active?)

      {
        name: 'assign',
        label: I18n.t('repositories.assign_record'),
        icon: 'sn-icon sn-icon-assign-to-task',
        type: :emit
      }
    end

    def duplicate_action
      return unless can_create_repository_rows?(@repository)

      return unless @repository_rows.all?(&:active?)

      {
        name: 'duplicate',
        label: I18n.t('repositories.copy_record'),
        icon: 'sn-icon sn-icon-duplicate',
        type: :emit
      }
    end

    def export_items_action
      return unless can_read_repository?(@repository)

      {
        name: 'export_records',
        label: I18n.t('repositories.exports.records'),
        icon: 'sn-icon sn-icon-export',
        type: :emit
      }
    end

    def export_consumption_action
      return unless can_export_repository_stock?(@repository)

      {
        name: 'export_consumption',
        label: I18n.t('repositories.exports.stock_consumption'),
        icon: 'sn-icon sn-icon-reports',
        item_id: @repository.id,
        type: :emit
      }
    end

    def export_actions
      {
        name: 'export_group',
        type: :group,
        group_label: I18n.t('repositories.exports.export'),
        actions: [export_items_action, export_consumption_action].compact
      }
    end

    def print_label_action
      return unless can_read_repository?(@repository)

      {
        name: 'print_label',
        label: I18n.t('repositories.print_label'),
        icon: 'sn-icon sn-icon-printer',
        type: :emit
      }
    end

    def archive_action
      return unless can_manage_repository_rows?(@repository)

      return unless @repository_rows.all?(&:active?)

      {
        name: 'archive',
        label: I18n.t('repositories.archive_record'),
        icon: 'sn-icon sn-icon-archive',
        type: :emit
      }
    end

    def delete_action
      return unless can_delete_repository_rows?(@repository)

      return unless @repository_rows.all?(&:archived?)

      {
        name: 'delete',
        label: I18n.t('repositories.delete_record'),
        icon: 'sn-icon sn-icon-delete',
        type: :emit
      }
    end
  end
end
