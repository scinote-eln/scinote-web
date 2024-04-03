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
                                .distinct
      @repository = @repositories.first
      @archived_state = @repositories.all.any?(&:archived?)
      @single = @repositories.uniq.length == 1
    end

    def actions
      return [] if @repositories.none?

      if @archived_state
        [export_action, restore_action, delete_action]
      else
        [rename_action, duplicate_action, export_action, archive_action, share_action]
      end.compact
    end

    private

    def rename_action
      return unless @single && can_manage_repository?(@repository)

      {
        name: :update,
        label: I18n.t('libraries.index.buttons.edit'),
        icon: 'sn-icon sn-icon-edit',
        type: :emit
      }
    end

    def duplicate_action
      return unless @single && can_create_repositories?(@current_team)

      {
        name: :duplicate,
        label: I18n.t('libraries.index.buttons.duplicate'),
        icon: 'sn-icon sn-icon-duplicate',
        type: :emit
      }
    end

    def export_action
      return unless @repositories.all? { |repository| can_read_repository?(repository) }

      {
        name: :export,
        label: I18n.t('libraries.index.buttons.export'),
        icon: 'sn-icon sn-icon-export',
        path: export_repositories_team_path(@current_team),
        export_limit: TeamZipExport.exports_limit,
        num_of_requests_left: @current_user.exports_left - 1,
        type: :emit
      }
    end

    def archive_action
      return unless @repositories.all? { |repository| can_archive_repository?(repository) }

      {
        name: :archive,
        label: I18n.t('libraries.index.buttons.archive'),
        icon: 'sn-icon sn-icon-archive',
        path: archive_team_repositories_path(@current_team),
        type: :emit
      }
    end

    def share_action
      return unless @single && can_share_repository?(@repository)

      {
        name: :share,
        label: I18n.t('repositories.index.share_inventory'),
        icon: 'sn-icon sn-icon-shared',
        type: :emit
      }
    end

    def restore_action
      return unless @repositories.all? { |repository| can_archive_repository?(repository) }

      {
        name: :restore,
        label: I18n.t('libraries.index.buttons.restore'),
        icon: 'sn-icon sn-icon-restore',
        path: restore_team_repositories_path(@current_team),
        type: :emit
      }
    end

    def delete_action
      return unless @single && can_delete_repository?(@repository)

      {
        name: :delete,
        label: I18n.t('libraries.index.buttons.delete'),
        icon: 'sn-icon sn-icon-delete',
        path: team_repository_path(@current_team, @repository),
        type: :emit
      }
    end
  end
end
