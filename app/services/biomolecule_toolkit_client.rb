# frozen_string_literal: true

class BiomoleculeToolkitClient
  MACROMOLECULES_PATH = '/api/macromolecules'

  class BiomoleculeToolkitClientException < StandardError; end

  def initialize
    @host = Rails.configuration.x.biomolecule_toolkit_host
    @http = Net::HTTP.new(
      Rails.configuration.x.biomolecule_toolkit_host,
      Rails.application.config.x.biomolecule_toolkit_port
    )
  end

  def healthy?
    request = Net::HTTP::Get.new('/api/health')
    process_request(request)&.dig('status') == 'UP'
  end

  def list
    request = Net::HTTP::Get.new(MACROMOLECULES_PATH)
    process_request(request)
  end

  def create(params:)
    request = Net::HTTP::Post.new(MACROMOLECULES_PATH, 'Content-Type': 'application/json')
    request.body = params
    process_request(request)
  end

  def get(cid:)
    request = Net::HTTP::Get.new("#{MACROMOLECULES_PATH}/#{CGI.escape(cid)}")
    process_request(request)
  end

  def update(cid:, params:)
    request = Net::HTTP::Put.new("#{MACROMOLECULES_PATH}/#{CGI.escape(cid)}", 'Content-Type': 'application/json')
    request.body = params
    process_request(request)
  end

  def delete
    request = Net::HTTP::Delete.new("#{MACROMOLECULES_PATH}/#{CGI.escape(cid)}")
    process_request(request)
  end

  private

  def process_request(request)
    response = @http.request(request)

    case response.class
    when Net::HTTPOK
      JSON.parse(response.body)
    when Net::HTTPNoContent
      true
    else
      error_message = JSON.parse(response.body).dig('error', 'message')
      error_message ||= I18n.t('biomolecule_toolkit_client.generic_error')
      raise BiomoleculeToolkitClientException, error_message
    end
  rescue JSON::ParserError
    raise BiomoleculeToolkitClientException, I18n.t('biomolecule_toolkit_client.response_parsing_error')
  rescue StandardError
    raise BiomoleculeToolkitClientException, I18n.t('biomolecule_toolkit_client.generic_error')
  end
end
