# frozen_string_literal: true

class MyModuleStatusConsequencesJob < ApplicationJob
  queue_as :high_priority

  def perform(my_module, my_module_status_consequences, status_changing_direction)
    error = nil
    my_module.transaction(requires_new: true) do
      my_module_status_consequences.each do |consequence|
        consequence.public_send(status_changing_direction, my_module)
      end
      my_module.update!(status_changing: false)

      # don't clear error if in transition error rollback state
      my_module.update!(last_transition_error: nil) unless my_module.transition_error_rollback
    rescue StandardError => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      error = if e.is_a?(MyModuleStatus::MyModuleStatusTransitionError)
                e.error
              else
                { type: :general, message: e.message }
              end
      raise ActiveRecord::Rollback
    end
    if error.present?
      my_module.transition_error_rollback = true
      my_module.my_module_status = my_module.changing_from_my_module_status
      my_module.last_transition_error = error
      my_module.status_changing = false
      my_module.save!
    end
  end
end
