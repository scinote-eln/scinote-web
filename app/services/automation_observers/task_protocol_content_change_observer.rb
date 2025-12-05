# frozen_string_literal: true

module AutomationObservers
  class TaskProtocolContentChangeObserver < BaseObserver
    OBJECT_ATTRIBUTES = {
      Protocol: %w(name description),
      Step: %w(created_at completed name position),
      StepText: %w(name text step_id),
      Checklist: %w(name step_id),
      ChecklistItem: %w(text position checked),
      Table: %w(name contents metadata),
      Asset: %w(file_file_name current_blob_id),
      StepAsset: %w(step_id asset_id),
      StepOrderableElement: %w(step_id position),
      Comment: %w(message),
      FormFieldValue: %w(not_applicable datetime datetime_to number number_to unit text selection flag data latest),
      FormResponse: %w(status discarded_at)
    }.freeze

    def self.on_create(element, user)
      # Handle creation of an empty protocol alongside with a task
      return if element.is_a?(Protocol)

      on_update(element, user)
    end

    def self.on_update(element, user, ignore_attributes: false)
      return unless Current.team.settings.dig('team_automation_settings', 'tasks', 'task_status_in_progress', 'on_protocol_content_change')

      protocol = nil

      case element.class.base_class.name
      when 'Table', 'StepAsset', 'Asset'
        return if element.step.blank?

        protocol = element.step.protocol
      when 'Checklist', 'StepText', 'StepOrderableElement'
        protocol = element.step.protocol
      when 'Comment'
        protocol = element.step.protocol if element.respond_to?(:step)
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
      return unless ignore_attributes || OBJECT_ATTRIBUTES[:"#{element.class.base_class.name}"]&.any? { |attr| element.public_send("saved_change_to_#{attr}?") }
      return unless protocol.in_module? && protocol.my_module.my_module_status.initial_status?
      return if element.respond_to?(:completed) && element.saved_change_to_completed? && !element.saved_change_to_created_at? && !element.completed

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
      on_update(element, user, ignore_attributes: true)
    end
  end
end
