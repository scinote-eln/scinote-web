# frozen_string_literal: true

class DueDateReminderJob < ApplicationJob
  def perform
    my_modules = MyModule.approaching_due_dates

    my_modules.each do |task|
      TaskDueDateNotification.send_notifications({ my_module_id: task.id })
    end
  end
end
