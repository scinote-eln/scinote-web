# frozen_string_literal: true

require 'rails_helper'

describe Activities::CreateActivityService do
  let(:webhook) { create :webhook }

  context 'when webhook is valid' do
    it 'executes webhook' do
      stub_request(:post, webhook.url).to_return(status: 200, body: "", headers: {})

      expect(WebhookService.new(webhook, { payload: "payload" }).send_webhook.response.code).to eq("200")
    end
  end

  context 'when webhook gets non-success HTTP response' do
    it 'logs error' do
      stub_request(:post, webhook.url).to_return(status: 500, body: "", headers: {})

      expect { WebhookService.new(webhook, { payload: "payload" }).send_webhook }.to(
        raise_error(WebhookService::RequestFailureException)
      )

      expect(webhook.last_error).to eq("500: ")
    end
  end

  context 'when webhook times out' do
    it 'logs error' do
      stub_request(:post, webhook.url).to_timeout

      expect { WebhookService.new(webhook, { payload: "payload" }).send_webhook }.to raise_error(Net::OpenTimeout)
      expect(webhook.last_error).to eq("execution expired")
    end
  end

  context 'when webhook url cannot be resolved' do
    it 'logs error' do
      stub_request(:post, webhook.url).to_raise(SocketError)

      expect { WebhookService.new(webhook, { payload: "payload" }).send_webhook }.to raise_error(SocketError)
      expect(webhook.last_error).to eq("Exception from WebMock")
    end
  end
end
