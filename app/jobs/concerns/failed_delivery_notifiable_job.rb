# frozen_string_literal: true

module FailedDeliveryNotifiableJob
  extend ActiveSupport::Concern

  included do
    before_enqueue do |job|
      unless job.arguments.last.is_a?(Hash) && job.arguments.last[:user_id].present?
        raise ArgumentError, 'required :user_id argument is missing! Needed for user notification in case of failure.'
      end
    end

    rescue_from StandardError do |e|
      logger.error e.message
      logger.error e.backtrace.join("\n")
      create_failed_notification!
      raise e
    end
  end

  private

  def create_failed_notification!
    @user = User.find_by(id: arguments.last[:user_id])
    return if @user.blank?

    DeliveryNotification.with(
      title: failed_notification_title,
      message: failed_notification_message,
      error: true
    ).deliver(@user)
  end

  def failed_notification_title
    I18n.t('activejob.failure_notifiable_job.general_notification_title')
  end

  def failed_notification_message
    I18n.backend.date_format = @user.settings[:date_format]
    timestamp = I18n.l(enqueued_at.in_time_zone(@user.time_zone), format: :full)
    I18n.t('activejob.failure_notifiable_job.general_notification_message', request_timestamp: timestamp)
  ensure
    I18n.backend.date_format = nil
  end
end
