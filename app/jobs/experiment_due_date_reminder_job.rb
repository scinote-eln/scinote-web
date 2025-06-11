# frozen_string_literal: true

class ExperimentDueDateReminderJob < ApplicationJob
  queue_as :default

  def perform
    NewRelic::Agent.ignore_transaction

    experiments_due.find_each do |experiment|
      ExperimentDueDateNotification
        .send_notifications({ experiment_id: experiment.id })
    end
  end

  private

  def experiments_due
    Experiment.joins(:project)
              .active
              .where(
                due_date_notification_sent: false,
                projects: { archived: false }
              )
              .where('experiments.due_date > ? AND experiments.due_date <= ?', Date.current, Date.current + 1.day)
  end
end
