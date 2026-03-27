# frozen_string_literal: true

module Toolbars
  class MyModuleUnassignedRepositoriesService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, repository, my_module, ids: [])
      @current_user = current_user
      @repository = repository
      @my_module = my_module
      @rows = repository.repository_rows.where(id: ids)

      @single = @rows.length == 1
    end

    def actions
      return [] if @rows.none?

      [
        assign_action,
        assign_downstream_action,
      ].compact
    end

    private

    def assign_action
      return unless can_assign_my_module_repository_rows?(@current_user, @my_module)

      {
        name: 'assign',
        label: I18n.t('my_modules.assigned_items.toolbar.assign'),
        icon: 'sn-icon sn-icon-task',
        type: :emit
      }
    end

    def assign_downstream_action
      return unless can_assign_my_module_repository_rows?(@current_user, @my_module)

      {
        name: 'assign_downstream',
        label: I18n.t('my_modules.assigned_items.toolbar.assign_downstream'),
        icon: 'sn-icon sn-icon-assign-to-task',
        type: :emit
      }
    end
  end
end
