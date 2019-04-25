# frozen_string_literal: true

require 'rails_helper'

describe Notifications::HandleSystemNotificationInCommunicationChannelService do
  let(:system_notification) { create :system_notification }
  let!(:user_system_notification) do
    create :user_system_notification, user: user, system_notification: system_notification
  end
  let(:user) { create :user }
  let(:service_call) do
    Notifications::HandleSystemNotificationInCommunicationChannelService.call(system_notification)
  end

  before do
    Delayed::Worker.delay_jobs = false
  end

  after do
    Delayed::Worker.delay_jobs = true
  end

  context 'when user has enabled notifications' do
    it 'calls AppMailer' do
      allow_any_instance_of(User).to receive(:system_message_email_notification).and_return(true)

      expect(AppMailer).to receive(:system_notification).and_return(double('Mailer', deliver: true))

      service_call
    end
  end

  context 'when user has disabled notifications' do
    it 'does not call AppMailer' do
      allow_any_instance_of(User).to receive(:system_message_email_notification).and_return(false)

      expect(AppMailer).not_to receive(:system_notification)

      service_call
    end
  end
end
