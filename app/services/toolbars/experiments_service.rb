# frozen_string_literal: true

module Toolbars
  class ExperimentsService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, experiment_ids: [])
      @current_user = current_user
      @experiments = Experiment.joins(:project)
                               .where(projects: { team_id: current_user.current_team_id })
                               .readable_by_user(current_user)
                               .where(id: experiment_ids)

      @single = @experiments.length == 1
    end

    def actions
      return [] if @experiments.none?

      [
        restore_action,
        edit_action,
        access_action,
        move_action,
        duplicate_action,
        archive_action
      ].compact
    end

    private

    def restore_action
      return unless @experiments.all? { |experiment| can_restore_experiment?(experiment) }

      {
        name: 'restore',
        label: I18n.t('experiments.toolbar.restore_button'),
        icon: 'sn-icon sn-icon-restore',
        path: restore_group_project_experiments_path(project_id: @experiments.first.project_id),
        type: :emit
      }
    end

    def edit_action
      return unless @single

      experiment = @experiments.first

      return unless can_manage_experiment?(experiment)

      {
        name: 'edit',
        label: I18n.t('experiments.index.edit_option'),
        icon: 'sn-icon sn-icon-edit',
        type: :emit
      }
    end

    def access_action
      return unless @single

      experiment = @experiments.first

      return unless can_read_experiment?(experiment)

      path = if can_manage_experiment_users?(experiment)
               edit_access_permissions_experiment_path(experiment)
             else
               access_permissions_experiment_path(experiment)
             end

      {
        name: 'access',
        label: I18n.t('general.access'),
        icon: 'sn-icon sn-icon-project-member-access',
        type: :emit
      }
    end

    def move_action
      return unless @experiments.all? { |experiment| can_move_experiment?(experiment) }

      {
        name: 'move',
        label: I18n.t('experiments.toolbar.move_button'),
        icon: 'sn-icon sn-icon-move',
        type: :emit,
        path: move_experiments_path(ids: @experiments.pluck(:id))
      }
    end

    def duplicate_action
      return unless @single

      experiment = @experiments.first

      return unless can_clone_experiment?(experiment)

      {
        name: 'duplicate',
        label: I18n.t('experiments.toolbar.duplicate_button'),
        icon: 'sn-icon sn-icon-duplicate',
        type: :emit
      }
    end

    def archive_action
      return unless @experiments.all? { |experiment| can_archive_experiment?(experiment) }

      {
        name: 'archive',
        label: I18n.t('experiments.toolbar.archive_button'),
        icon: 'sn-icon sn-icon-archive',
        path: archive_group_project_experiments_path(project_id: @experiments.first.project_id),
        type: :emit
      }
    end
  end
end
