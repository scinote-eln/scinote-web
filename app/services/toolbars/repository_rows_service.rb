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
        duplicate_action,
        export_action,
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
        icon: 'fas fa-undo',
        button_class: 'resotre-repository-row-btn',
        button_id: 'restoreRepositoryRecords',
        type: :legacy
      }
    end

    def edit_action
      return unless can_manage_repository_rows?(@repository)

      {
        name: 'edit',
        label: I18n.t('repositories.edit_record'),
        icon: 'fas fa-pencil-alt',
        button_class: 'edit-repository-row-btn',
        button_id: 'editRepositoryRecord',
        type: :legacy
      }
    end

    def duplicate_action
      return unless can_create_repository_rows?(@repository)

      {
        name: 'duplicate',
        label: I18n.t('repositories.copy_record'),
        icon: 'fas fa-copy',
        button_class: 'copy-repository-row-btn',
        button_id: 'copyRepositoryRecords',
        type: :legacy
      }
    end

    def export_action
      return unless can_read_repository?(@repository)

      {
        name: 'export',
        label: I18n.t('repositories.export_record'),
        icon: 'fas fa-file-export',
        button_class: 'export-repository-row-btn',
        button_id: 'exportRepositoriesButton',
        type: :legacy
      }
    end

    def print_label_action
      return unless can_read_repository?(@repository)

      {
        name: 'print_label',
        label: I18n.t('repositories.print_label'),
        icon: 'fas fa-print',
        button_class: 'print-label-button',
        button_id: 'toolbarPrintLabel',
        type: :legacy
      }
    end

    def archive_action
      return unless can_manage_repository_rows?(@repository)

      return unless @repository_rows.all?(&:active?)

      {
        name: 'archive',
        label: I18n.t('repositories.archive_record'),
        icon: 'fas fa-archive',
        button_class: 'resotre-repository-row-btn',
        button_id: 'archiveRepositoryRecordsButton',
        type: :legacy
      }
    end

    def delete_action
      return unless can_delete_repository_rows?(@repository)

      return unless @repository_rows.all?(&:archived?)

      {
        name: 'delete',
        label: I18n.t('repositories.delete_record'),
        icon: 'fas fa-trash',
        button_class: 'resotre-repository-row-btn',
        button_id: 'deleteRepositoryRecords',
        type: :legacy
      }
    end
  end
end
