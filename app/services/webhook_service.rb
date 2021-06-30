# frozen_string_literal: true

class WebhookService
  class InactiveWebhookSendException < StandardError; end

  DISABLE_WEBHOOK_ERROR_THRESHOLD = 10

  def initialize(webhook, payload)
    @webhook = webhook
    @payload = payload
  end

  def send_webhook
    unless @webhook.active?
      raise(
        Activities::WebhooksService::InactiveWebhookSendException,
        'Refused to send inactive webhook.'
      )
    end

    response = HTTParty.public_send(
      @webhook.http_method,
      @webhook.url,
      {
        headers: { 'Content-Type' => 'application/json' },
        body: @payload
      }
    )

    log_error!("#{response.code}: #{response.message}") unless response.success?

    response
  rescue Net::ReadTimeout, Net::OpenTimeout, SocketError => e
    log_error!(e)
    raise e
  ensure
    disable_webhook_if_broken!
  end

  private

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
