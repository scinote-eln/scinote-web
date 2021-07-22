# frozen_string_literal: true

module Activities
  class SendWebhookJob < ApplicationJob
    queue_as :webhooks

    retry_on StandardError, attempts: 3, wait: :exponentially_longer

    def perform(webhook, activity)
      Activities::ActivityWebhookService.new(webhook, activity).send_webhook
    end
  end
end
