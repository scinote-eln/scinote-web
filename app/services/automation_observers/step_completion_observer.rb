# frozen_string_literal: true

module AutomationObservers
  class StepCompletionObserver < BaseObserver
    def self.on_update(step, user)
      return unless Current.team.settings.dig('team_automation_settings', 'tasks', 'task_status_in_progress', 'on_step_completion')
      return unless step.saved_change_to_completed? && step.completed
      return unless step.protocol.in_module? && step.protocol.my_module.my_module_status.initial_status?

      my_module = step.protocol.my_module
      previous_status_id = my_module.my_module_status.id
      my_module.update!(my_module_status: my_module.my_module_status.next_status, last_modified_by: user)

      Activities::CreateActivityService
        .call(activity_type: :automation_task_status_changed,
              owner: user,
              team: my_module.team,
              project: my_module.project,
              subject: my_module,
              message_items: {
                my_module: my_module.id,
                my_module_status_old: previous_status_id,
                my_module_status_new: my_module.my_module_status.id
              })
    end
  end
end
