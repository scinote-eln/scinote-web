# frozen_string_literal: true

module Activities
  class ActivityWebhookService
    def initialize(webhook, activity)
      @webhook = webhook
      @activity = activity
    end

    def send_webhook
      WebhookService.new(@webhook, activity_payload).send_webhook
    end

    def activity_payload
      @activity.values.merge(
        type: @activity.type_of,
        created_at: @activity.created_at
      )
    end
  end
end
