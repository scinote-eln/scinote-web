# frozen_string_literal: true

require 'rails_helper'

describe Activities::DispatchWebhooksJob do
  let!(:activity_filter_1) { create :activity_filter }
  let!(:activity_filter_2) { create :activity_filter }
  let!(:non_matching_activity_filter) do
    create(
      :activity_filter,
      filter: { 'types' => ['163'], 'from_date' => '', 'to_date' => '' }
    )
  end
  let!(:webhook_1) { create :webhook, activity_filter: activity_filter_1 }
  let!(:webhook_2) { create :webhook, activity_filter: activity_filter_2 }
  let!(:webhook_3) { create :webhook, activity_filter: non_matching_activity_filter }
  let(:activity) { create :activity }

  it 'enqueues webhook jobs' do
    ActiveJob::Base.queue_adapter = :test

    expect { Activities::DispatchWebhooksJob.new(activity).perform_now }
      .to have_enqueued_job(Activities::SendWebhookJob).exactly(2).times
  end
end
