# frozen_string_literal: true

module Activities
  class WebhookService
    DISABLE_WEBHOOK_ERROR_THRESHOLD = 10

    def initialize(webhook, activity)
      @webhook = webhook
      @activity = activity
    end

    def send_webhook
      raise "Cannot send inactive webhook." unless @webhook.active?

      response = HTTParty.send(
        @webhook.method,
        @webhook.url,
        {
          headers: { 'Content-Type' => 'application/json' },
          body: activity_payload
        }
      )

      unless response.success?
        log_error!("#{response.status}: #{response.message}")
      end
    rescue Net::ReadTimeout, SocketError => error
      log_error!(error)
    ensure
      disable_webhook_if_broken!
    end

    private

    def activity_payload
      @activity.values.merge(
        type: @activity.type_of,
        created_at: @activity.created_at
      )
    end

    def log_error!(message)
      error_count = @webhook.error_count + 1

      @webhook.update(
        error_count: error_count,
        last_error: message
      )
    end

    def disable_webhook_if_broken!
      return if @webhook.error_count < DISABLE_WEBHOOK_ERROR_THRESHOLD
      @webhook.update(active: false)
    end
  end
end
