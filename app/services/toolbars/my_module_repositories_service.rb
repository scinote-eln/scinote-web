# frozen_string_literal: true

module Toolbars
  class MyModuleRepositoriesService
    attr_reader :current_user

    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    def initialize(current_user, my_module, ids: [])
      @current_user = current_user
      @my_module = my_module
      @rows = my_module.my_module_repository_rows.where(id: ids)

      @single = @rows.length == 1
    end

    def actions
      return [] if @rows.none?

      [
        export_consumption,
        print_action
      ].compact
    end

    private

    def print_action
      {
        name: 'print',
        label: I18n.t('my_modules.assigned_items.toolbar.print'),
        icon: 'sn-icon sn-icon-printer',
        type: :emit
      }
    end

    def export_consumption
      {
        name: 'export_consumption',
        label: I18n.t('my_modules.assigned_items.toolbar.export_consumption'),
        icon: 'sn-icon sn-icon-export',
        type: :emit
      }
    end
  end
end
