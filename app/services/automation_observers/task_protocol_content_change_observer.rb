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

      case element.class.base_class.name
      when 'Asset', 'Table'
        return if element.step.blank?

        protocol = element.step.protocol
      when 'Checklist', 'StepText', 'Comment', 'StepOrderableElement'
        protocol = element.step.protocol
      when 'ChecklistItem'
        protocol = element.checklist.step.protocol
      when 'FormFieldValue'
        protocol = element.form_response&.step&.protocol
      when 'FormResponse'
        protocol = element&.step&.protocol
      when 'Step'
        protocol = element.protocol
      when 'Protocol'
        protocol = element
      end

      return if protocol.blank?
      return unless protocol.in_module? && protocol.my_module.my_module_status.initial_status?
      return if element.respond_to?(:completed) && element.saved_change_to_completed? && !element.completed
      return if (element.respond_to?(:view_mode) && element.saved_change_to_view_mode?) || (element.respond_to?(:assets_view_mode) && element.saved_change_to_assets_view_mode?)

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

    def self.on_destroy(element, user)
      on_update(element, user)
    end
  end
end
