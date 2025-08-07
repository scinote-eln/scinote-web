# frozen_string_literal: true

module AutomationObservers
  class ProtocolContentChangedAutomationObserver
    def initialize(step, user)
      @step = step
      @my_module = step&.my_module
      @user = user
    end

    def call
      return if @step.blank?
      return unless @step.protocol.in_module?
      return unless @my_module.team.settings.dig('team_automation_settings', 'protocol_content_added')
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
