# frozen_string_literal: true

module Toolbars
  class RepositoriesService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, current_team, repository_ids: [])
      @current_user = current_user
      @current_team = current_team
      @repositories = Repository.readable_by_user(current_user)
                                .where(id: repository_ids)
      @repository = @repositories.first
      @archived_state = @repositories.all.any?(&:archived?)
      @single = @repositories.uniq.length == 1
    end

    def actions
      return [] if @repositories.none?

      if @archived_state
        [restore_action, delete_action]
      else
        [rename_action, duplicate_action, archive_action, share_action]
      end.compact
    end

    private

    def rename_action
      return unless @single && can_manage_repository?(@repository)

      {
        name: 'rename',
        label: I18n.t('libraries.index.buttons.edit'),
        button_id: 'renameRepoBtn',
        icon: 'fas fa-pencil-alt',
        path: team_repository_rename_modal_path(@current_team, repository_id: @repository),
        type: 'remote-modal'
      }
    end

    def duplicate_action
      return unless @single && can_create_repositories?(@current_team)

      {
        name: 'duplicate',
        label: I18n.t('libraries.index.buttons.duplicate'),
        button_id: 'copyRepoBtn',
        icon: 'fas fa-copy',
        path: team_repository_copy_modal_path(@current_team, repository_id: @repository),
        type: 'remote-modal'
      }
    end

    def archive_action
      return unless @repositories.all? { |repository| can_archive_repository?(repository) }

      {
        name: 'archive',
        label: I18n.t('libraries.index.buttons.archive'),
        button_id: 'archiveRepoBtn',
        icon: 'fas fa-archive',
        path: archive_team_repositories_path(@current_team),
        type: :request,
        request_method: :post
      }
    end

    def share_action
      return unless @single && can_share_repository?(@repository)

      {
        name: 'share',
        label: I18n.t('repositories.index.share_inventory'),
        icon: 'fas fa-user-plus',
        button_class: 'share-repository-button',
        path: team_repository_share_modal_path(@current_team, repository_id: @repository),
        type: 'remote-modal'
      }
    end

    def restore_action
      return unless @repositories.all? { |repository| can_archive_repository?(repository) }

      {
        name: 'restore',
        label: I18n.t('libraries.index.buttons.restore'),
        icon: 'fas fa-undo',
        button_id: 'restoreRepoBtn',
        path: restore_team_repositories_path(@current_team),
        type: :request,
        request_method: :post
      }
    end

    def delete_action
      return unless @single && can_delete_repository?(@repository)

      {
        name: 'delete',
        label: I18n.t('libraries.index.buttons.delete'),
        icon: 'fas fa-trash',
        button_id: 'deleteRepoBtn',
        path: team_repository_destroy_modal_path(@current_team, repository_id: @repository),
        type: 'remote-modal'
      }
    end
  end
end
