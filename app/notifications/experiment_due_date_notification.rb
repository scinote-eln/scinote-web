# frozen_string_literal: true

class ExperimentDueDateNotification < BaseNotification
  def self.subtype
    :experiments_due_date_reminder
  end

  def title
    I18n.t(
      'notifications.content.experiment_due_date_reminder.message_html',
      experiment_name: subject.name
    )
  end

  def subject
    Experiment.find(params[:experiment_id])
  end

  after_deliver do
    # rubocop:disable Rails/SkipsModelValidations
    Experiment.find(params[:experiment_id]).update_column(:due_date_notification_sent, true)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
