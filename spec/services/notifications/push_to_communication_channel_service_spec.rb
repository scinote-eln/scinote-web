# frozen_string_literal: true

require 'rails_helper'

describe Notifications::PushToCommunicationChannelService do
  let(:system_notification) { create :system_notification }
  let(:service_call) do
    Notifications::PushToCommunicationChannelService.call(item_id: system_notification.id,
                                                          item_type: system_notification.class.name)
  end

  context 'when call with valid items' do
    it 'call service to to handle sending out' do
      expect(Notifications::HandleSystemNotificationInCommunicationChannelService)
        .to receive(:call).with(system_notification)

      service_call
    end
  end

  context 'when call with not valid items' do
    it 'returns error with key invalid_arguments when system notification not exists' do
      allow(SystemNotification).to receive(:find).and_return(nil)

      expect(service_call.errors).to have_key(:invalid_arguments)
    end

    it 'raise error when have not listed object' do
      u = create :user

      expect do
        Notifications::PushToCommunicationChannelService.call(item_id: u.id, item_type: 'User')
      end.to(raise_error('Dont know how to handle this type of items'))
    end
  end
end
