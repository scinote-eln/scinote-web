# frozen_string_literal: true

module AutomationObservers
  class ResultCreateAutomationObserver
    def initialize(my_module, user)
      @my_module = my_module
      @user = user
    end

    def call
      return @my_module.team.settings.dig('team_automation_settings', 'task_result_added') unless @my_module.team.settings.dig('team_automation_settings', 'task_result_added')
      return unless @my_module.my_module_status.initial_status?

      previous_status_id = @my_module.my_module_status.id
      @my_module.update!(my_module_status: @my_module.my_module_status.next_status)

      Activities::CreateActivityService
        .call(activity_type: :automation_task_status_changed,
              owner: @user,
              team: @my_module.team,
              project: @my_module.project,
              subject: @my_module,
              message_items: {
                my_module: @my_module.id,
                my_module_status_old: previous_status_id,
                my_module_status_new: @my_module.my_module_status.id
              })
    end
  end
end
