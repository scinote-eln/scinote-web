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
        icon: 'fas fa-undo',
        button_class: 'restore-experiments-btn',
        path: restore_group_project_experiments_path(project_id: @experiments.first.project_id),
        type: :request,
        request_method: :post
      }
    end

    def edit_action
      return unless @single

      experiment = @experiments.first

      return unless can_manage_experiment?(experiment)

      {
        name: 'edit',
        label: I18n.t('experiments.index.edit_option'),
        icon: 'fa fa-pencil-alt',
        button_class: 'edit-btn',
        path: edit_experiment_path(experiment),
        type: 'remote-modal'
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
        icon: 'fa fa-door-open',
        button_class: 'access-btn',
        path: path,
        type: 'remote-modal'
      }
    end

    def move_action
      return unless @single

      experiment = @experiments.first

      return unless can_move_experiment?(experiment)

      {
        name: 'move',
        label: I18n.t('experiments.toolbar.move_button'),
        icon: 'fas fa-arrow-right',
        button_class: 'move-experiments-btn',
        path: move_modal_experiments_path(id: experiment.id),
        type: 'remote-modal'
      }
    end

    def duplicate_action
      return unless @single

      experiment = @experiments.first

      return unless can_clone_experiment?(experiment)

      {
        name: 'duplicate',
        label: I18n.t('experiments.toolbar.duplicate_button'),
        icon: 'fas fa-copy',
        button_class: 'clone-experiment-btn',
        path: clone_modal_experiments_path(id: experiment.id),
        type: 'remote-modal',
        request_method: :get
      }
    end

    def archive_action
      return unless @experiments.all? { |experiment| can_archive_experiment?(experiment) }

      {
        name: 'archive',
        label: I18n.t('experiments.toolbar.archive_button'),
        icon: 'fas fa-archive',
        button_class: 'archive-experiments-btn',
        path: archive_group_project_experiments_path(project_id: @experiments.first.project_id),
        type: :request,
        request_method: :post
      }
    end
  end
end
