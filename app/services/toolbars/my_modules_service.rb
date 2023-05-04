# frozen_string_literal: true

module Toolbars
  class MyModulesService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, my_module_ids: [])
      @current_user = current_user
      @my_modules = MyModule.joins(experiment: :project)
                            .where(projects: { team_id: current_user.current_team_id })
                            .readable_by_user(current_user)
                            .where(id: my_module_ids)

      @single = @my_modules.length == 1
    end

    def actions
      return [] if @my_modules.none?

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
      return unless @my_modules.all? { |my_module| can_restore_my_module?(my_module) }

      experiment = @my_modules.first.experiment

      {
        name: 'restore',
        label: I18n.t('experiments.table.toolbar.restore'),
        icon: 'fas fa-undo',
        button_class: 'restore-my-modules-btn',
        button_id: 'restoreTask',
        path: restore_my_modules_experiment_path(experiment),
        type: :legacy
      }
    end

    def edit_action
      return unless @single

      my_module = @my_modules.first

      return unless can_manage_my_module?(my_module)

      {
        name: 'edit',
        label: I18n.t('experiments.table.toolbar.edit'),
        icon: 'fa fa-pencil-alt',
        button_id: 'editTask',
        type: :legacy
      }
    end

    def access_action
      return unless @single

      my_module = @my_modules.first

      return unless can_read_my_module?(my_module)

      path = if can_manage_my_module_users?(my_module)
               edit_access_permissions_my_module_path(my_module)
             else
               access_permissions_my_module_path(my_module)
             end

      {
        name: 'access',
        label: I18n.t('experiments.table.my_module_actions.access'),
        icon: 'fa fa-door-open',
        button_class: 'access-btn',
        path: path,
        type: 'remote-modal'
      }
    end

    def move_action
      return unless @single

      my_module = @my_modules.first

      return unless can_move_my_module?(my_module)

      {
        name: 'move',
        label: I18n.t('experiments.table.toolbar.move'),
        icon: 'fas fa-arrow-right',
        button_id: 'moveTask',
        button_class: 'move-my-modules-btn',
        type: :legacy
      }
    end

    def duplicate_action
      experiment = @my_modules.first.experiment

      return unless @my_modules.all?(&:active?)
      return unless can_manage_experiment?(experiment)

      {
        name: 'duplicate',
        label: I18n.t('experiments.table.toolbar.duplicate'),
        icon: 'fas fa-copy',
        button_id: 'duplicateTasks',
        button_class: 'duplicate-tasks-btn',
        path: batch_clone_my_modules_experiment_path(experiment),
        type: :legacy
      }
    end

    def archive_action
      return unless @my_modules.all? { |my_module| can_archive_my_module?(my_module) }

      experiment = @my_modules.first.experiment

      {
        name: 'archive',
        label: I18n.t('experiments.table.toolbar.archive'),
        icon: 'fas fa-archive',
        button_id: 'archiveTask',
        path: archive_my_modules_experiment_path(experiment),
        type: :legacy
      }
    end
  end
end
