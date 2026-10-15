# frozen_string_literal: true

require 'rails_helper'

describe FailedDeliveryNotifiableJob, type: :job do
  let(:user) do
    create :user, time_zone: 'UTC'
  end

  let(:job_class) do
    Class.new(ApplicationJob) do
      include FailedDeliveryNotifiableJob

      def self.name
        'FailingTestJob'
      end

      def perform(*_args)
        raise StandardError, 'job exploded'
      end
    end
  end

  it 'refuses to enqueue a job without a user_id option' do
    expect { job_class.perform_later(1) }.to raise_error(ArgumentError, /:user_id argument is missing/)
    expect { job_class.perform_later(user_id: nil) }.to raise_error(ArgumentError, /:user_id/)
  end

  it 'enqueues when a user_id is given' do
    ActiveJob::Base.queue_adapter = :test

    expect { job_class.perform_later(user_id: user.id) }.to have_enqueued_job(job_class)
  end

  describe 'failure' do
    let(:job) do
      job_class.new(user_id: user.id).tap { |j| j.enqueued_at = Time.utc(2024, 5, 6, 7, 8, 9) }
    end

    it 'logs, notifies the user with the general message and re-raises' do
      allow(Rails.logger).to receive(:error)

      expect { job.perform_now }.to raise_error(StandardError, 'job exploded')
        .and change { user.notifications.count }.by(1)

      notification = user.notifications.last.to_notification
      expect(notification.title).to eq I18n.t('activejob.failure_notifiable_job.general_notification_title')
      expect(notification.message).to include('2024')
      expect(user.notifications.last.params[:error]).to be true
    end

    it 'does not notify when the user no longer exists, but still re-raises' do
      job = job_class.new(user_id: -1)
      job.enqueued_at = Time.current

      expect { job.perform_now }.to raise_error(StandardError, 'job exploded')
      expect(Notification.count).to eq 0
    end
  end
end
