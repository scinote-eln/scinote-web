# frozen_string_literal: true

module AutomationObservers
  class ResultContentChangeObserver < BaseObserver
    def self.on_create(element, user)
      on_update(element, user)
    end

    def self.on_update(element, user)
      return unless Current.team.settings.dig('team_automation_settings', 'tasks', 'task_status_in_progress', 'on_result_created_or_changed')

      result = if element.is_a?(Result)
                 element
               elsif element.respond_to?(:result)
                 element.result
               end

      return if result.blank?
      return if result.is_a?(ResultTemplate)

      return if result.archived_previously_changed?
      return unless result.my_module.my_module_status.initial_status?

      my_module = result.my_module
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
