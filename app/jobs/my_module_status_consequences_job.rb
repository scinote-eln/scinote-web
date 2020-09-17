# frozen_string_literal: true

class MyModuleStatusConsequencesJob < ApplicationJob
  queue_as :high_priority

  def perform(my_module, my_module_status_consequences)
    error_raised = false
    my_module.transaction do
      my_module_status_consequences.each do |consequence|
        consequence.call(my_module)
      end
      my_module.update!(status_changing: false)
    rescue StandardError => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      error_raised = true
    end
    if error_raised
      my_module.my_module_status = my_module.changing_from_my_module_status
      my_module.status_changing = false
      my_module.save!
    end
  end
end
