# frozen_string_literal: true

class ProjectDueDateReminderJob < ApplicationJob
  queue_as :default

  def perform
    NewRelic::Agent.ignore_transaction

    projects_due.find_each do |project|
      ProjectDueDateNotification
        .send_notifications({ project_id: project.id })
    end
  end

  private

  def projects_due
    Project.active
           .where(due_date_notification_sent: false)
           .where('projects.due_date > ? AND projects.due_date <= ?', Date.current, Date.current + 1.day)
  end
end
