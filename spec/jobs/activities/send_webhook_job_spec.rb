# frozen_string_literal: true

require 'rails_helper'

describe Activities::SendWebhookJob do
  let(:webhook) { create :webhook }
  let(:activity) { create :activity }

  it 'sends the webhook' do
    stub_request(:post, webhook.url).to_return(status: 200, body: "", headers: {})

    expect(Activities::SendWebhookJob.new(webhook, activity).perform_now.response.code).to eq("200")
  end
end
