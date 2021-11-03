# frozen_string_literal: true

class WebhookService
  class InactiveWebhookSendException < StandardError; end

  class RequestFailureException < StandardError; end

  def initialize(webhook, payload)
    @webhook = webhook
    @payload = payload
  end

  def send_webhook
    unless @webhook.active?
      raise(
        InactiveWebhookSendException,
        'Refused to send inactive webhook.'
      )
    end

    headers = { 'Content-Type' => 'application/json' }
    headers['Webhook-Secret-Key'] = @webhook.secret_key if @webhook.secret_key.present?

    response = HTTParty.public_send(
      @webhook.http_method,
      @webhook.url,
      {
        headers: headers,
        body: @payload.to_json
      }
    )

    unless response.success?
      error_description = "#{response.code}: #{response.message}"
      log_error!(error_description)

      raise(
        RequestFailureException,
        error_description
      )
    end

    response
  rescue Net::ReadTimeout, Net::OpenTimeout, SocketError => e
    log_error!(e)
    raise e
  end

  private

  def log_error!(message)
    @webhook.update!(
      last_error: message
    )
  end
end
