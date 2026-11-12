# frozen_string_literal: true

require 'rails_helper'

describe NotificationCleanupJob, type: :job do
  let!(:old) { create :notification, type: 'DeliveryNotification' }
  let!(:recent) { create :notification, type: 'DeliveryNotification' }

  before do
    allow(NewRelic::Agent).to receive(:ignore_transaction)
    old.update_columns(created_at: 4.months.ago)
    recent.update_columns(created_at: 2.months.ago)
  end

  it 'deletes notifications older than three months and keeps newer ones' do
    expect { described_class.perform_now }.to change(Notification, :count).by(-1)

    expect(Notification.exists?(old.id)).to be false
    expect(Notification.exists?(recent.id)).to be true
    expect(NewRelic::Agent).to have_received(:ignore_transaction)
  end
end
