# frozen_string_literal: true

module Activities
  class DispatchWebhooksJob < ApplicationJob
    queue_as :high_priority

    def perform(activity)
      webhooks =
        Webhook.active.where(
          activity_filter_id:
            Activities::ActivityFilterMatchingService.new(activity).activity_filters.select(:id)
        )

      webhooks.each do |webhook|
        Activities::SendWebhookJob.perform_later(webhook, activity)
      end
    end
  end
end
