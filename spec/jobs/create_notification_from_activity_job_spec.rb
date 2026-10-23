# frozen_string_literal: true

require 'rails_helper'

describe CreateNotificationFromActivityJob, type: :job do
  it 'asks the activity to generate its notification on the high priority queue' do
    activity = instance_double(Activity, generate_notification_from_activity: true)

    described_class.perform_now(activity)

    expect(activity).to have_received(:generate_notification_from_activity)
    expect(described_class.new.queue_name).to eq 'high_priority'
  end
end
