# frozen_string_literal: true

class TaskDueDateNotification < BaseNotification
  def self.subtype
    :my_module_due_date_reminder
  end

  def title
    I18n.t(
      'notifications.content.my_module_due_date_reminder.message_html',
      my_module_name: subject.name
    )
  end

  def subject
    MyModule.find(params[:my_module_id])
  end

  after_deliver do
    MyModule.find(params[:my_module_id]).update_column(:due_date_notification_sent, true)
  end
end
