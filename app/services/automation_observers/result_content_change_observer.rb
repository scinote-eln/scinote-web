# frozen_string_literal: true

module AutomationObservers
  class ResultContentChangeObserver < BaseObserver
    OBJECT_ATTRIBUTES = {
      Protocol: %w(name description),
      ResultBase: %w(created_at name discarded_at),
      ResultText: %w(name text result_id),
      Table: %w(name contents metadata),
      Asset: %w(file_file_name current_blob_id),
      ResultAsset: %w(result_id asset_id),
      ResultOrderableElement: %w(result_id position),
      Comment: %w(message)
    }.freeze

    def self.on_create(element, user)
      on_update(element, user)
    end

    def self.on_update(element, user, ignore_attributes: false)
      return unless Current.team.settings.dig('team_automation_settings', 'tasks', 'task_status_in_progress', 'on_result_created_or_changed')

      result = if element.is_a?(Result)
                 element
               elsif element.respond_to?(:result_asset)
                 element.result_asset&.result
               elsif element.respond_to?(:result)
                 element.result
               end

      return if result.blank?
      return if result.is_a?(ResultTemplate)

      return unless result.my_module.my_module_status.initial_status?
      return unless ignore_attributes || OBJECT_ATTRIBUTES[:"#{element.class.base_class.name}"]&.any? { |attr| element.public_send("saved_change_to_#{attr}?") }

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
      on_update(element, user, ignore_attributes: true)
    end
  end
end
