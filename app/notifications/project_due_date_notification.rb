# frozen_string_literal: true

class ProjectDueDateNotification < BaseNotification
  def self.subtype
    :projects_due_date_reminder
  end

  def title
    I18n.t(
      'notifications.content.project_due_date_reminder.message_html',
      project_name: subject.name
    )
  end

  def subject
    Project.find(params[:project_id])
  end

  after_deliver do
    # rubocop:disable Rails/SkipsModelValidations
    Project.find(params[:project_id]).update_column(:due_date_notification_sent, true)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
