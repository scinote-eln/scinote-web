# frozen_string_literal: true

module AutomationObservers
  class TaskProtocolContentChangeObserver < BaseObserver
    def self.on_create(element, user)
      # Handle creation of an empty protocol alongside with a task
      return if element.is_a?(Protocol)

      on_update(element, user)
    end

    def self.on_update(element, user)
      return unless Current.team.settings.dig('team_automation_settings', 'tasks', 'task_status_in_progress', 'on_protocol_content_change')

      protocol = nil

      case element.class.name
      when 'Asset', 'Table'
        return if element.step.blank?

        protocol = element.step.protocol
      when 'Checklist', 'StepText', 'StepComment', 'StepOrderableElement'
        protocol = element.step.protocol
      when 'ChecklistItem'
        protocol = element.checklist.step.protocol
      when 'FormFieldValue'
        protocol = element.form_response.step.protocol
      when 'Step'
        protocol = element.protocol
      when 'Protocol'
        protocol = element
      end

      return if protocol.blank?
      return unless protocol.in_module? && protocol.my_module.my_module_status.initial_status?

      my_module = protocol.my_module
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
