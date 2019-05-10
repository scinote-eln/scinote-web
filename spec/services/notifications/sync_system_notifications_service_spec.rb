# frozen_string_literal: true

require 'rails_helper'

describe Notifications::SyncSystemNotificationsService do
  url = 'http://system-notifications-service.test/api/system_notifications'
  let!(:user) { create :user }
  let(:service_call) do
    allow_any_instance_of(Notifications::PushToCommunicationChannelService).to receive(:call).and_return(nil)

    Notifications::SyncSystemNotificationsService.call
  end

  let(:first_call_result) do
    notifications = (1..10).map do |id|
      FactoryBot.attributes_for(:system_notification)
                .merge('source_id': id)
    end
    { notifications: notifications }
  end

  before(:all) do
    Timecop.freeze
  end

  after(:all) do
    Timecop.return
  end

  context 'when request is successful' do
    before do |test|
      if test.metadata[:add_notifications_before]
        create :system_notification,
               source_id: 10,
               last_time_changed_at: 10.days.ago.to_datetime
      end

      stub_request(:get, url)
        .with(query: { 'last_sync_timestamp':
                         SystemNotification.last_sync_timestamp,
                       'channels_slug': 'test-channel' },
              headers: { 'accept':
                           'application/vnd.system-notifications.1+json' })
        .to_return(body: first_call_result.to_json,
                   status: 200,
                   headers: { 'Content-Type': 'application/json' })
    end

    it 'adds 10 notifictions into db' do
      expect { service_call }.to(change { SystemNotification.all.count }.by(10))
    end

    it 'does not add 10 notifications because ther are already in DB' do
      first_call_result[:notifications].each do |sn|
        SystemNotification.create(sn)
      end

      expect { service_call }.not_to(change { SystemNotification.all.count })
    end

    it 'updates existing notification', add_notifications_before: true do
      expect { service_call }
        .to(change { SystemNotification.last.last_time_changed_at })
    end

    it 'add only 3 notifications' do
      first_call_result[:notifications][2..8].each do |sn|
        SystemNotification.create(sn)
      end

      expect { service_call }.to(change { SystemNotification.all.count }.by(3))
    end

    it 'return error when last_sync_timestamp is nil' do
      allow(SystemNotification).to receive(:last_sync_timestamp).and_return(nil)

      expect(service_call.errors).to have_key(:last_sync_timestamp)
    end

    it 'adds 20 user_system_notifications records' do
      create :user # add another user, so have 2 users in DB

      expect { service_call }.to change { UserSystemNotification.count }.by(20)
    end

    it 'calls service to notify users about notification' do
      Delayed::Worker.delay_jobs = false
      expect(Notifications::PushToCommunicationChannelService).to receive(:call).exactly(10)

      service_call
      Delayed::Worker.delay_jobs = true
    end
  end

  context 'when request is unsuccessful' do
    before do
      stub_request(:get, url)
        .with(query: { 'last_sync_timestamp':
                         SystemNotification.last_sync_timestamp,
                       'channels_slug': 'test-channel' })
        .to_return(status: [500, 'Internal Server Error'])
    end

    it 'returns api_error with message' do
      expect(service_call.errors).to have_key(:api_error)
    end

    it 'returns error with description about itself' do
      allow(Notifications::SyncSystemNotificationsService)
        .to receive(:get).and_raise(SocketError)

      expect(service_call.errors).to have_key(:socketerror)
    end

    it 'does not call service to notify users about notification' do
      Delayed::Worker.delay_jobs = false
      expect(Notifications::PushToCommunicationChannelService).to_not receive(:call)

      service_call
      Delayed::Worker.delay_jobs = true
    end
  end
end
