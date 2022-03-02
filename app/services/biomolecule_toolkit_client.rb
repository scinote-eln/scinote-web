# frozen_string_literal: true

class BiomoleculeToolkitClient
  MACROMOLECULES_PATH = '/api/macromolecules'
  MACROMOLECULES_ATTRIBUTES_PATH = '/api/admin/attributes/MACROMOLECULE'

  class BiomoleculeToolkitClientException < StandardError; end

  def initialize
    @uri = URI.parse(Rails.application.config.x.biomolecule_toolkit_base_url)
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @http.use_ssl = (@uri.scheme == 'https')
  end

  def healthy?
    request = Net::HTTP::Get.new(build_request_path('/api/health'))
    process_request(request)&.dig('status') == 'UP'
  end

  def list_attributes
    request = Net::HTTP::Get.new(build_request_path(MACROMOLECULES_ATTRIBUTES_PATH))
    process_request(request)
  end

  def list
    request = Net::HTTP::Get.new(build_request_path(MACROMOLECULES_PATH))
    process_request(request)
  end

  def create(params:)
    request = Net::HTTP::Post.new(build_request_path(MACROMOLECULES_PATH))
    request.body = params
    process_request(request)
  end

  def get(cid:)
    request = Net::HTTP::Get.new(build_request_path("#{MACROMOLECULES_PATH}/#{CGI.escape(cid)}"))
    process_request(request)
  end

  def update(cid:, params:)
    request = Net::HTTP::Put.new(build_request_path("#{MACROMOLECULES_PATH}/#{CGI.escape(cid)}"))
    request.body = params
    process_request(request)
  end

  def delete
    request = Net::HTTP::Delete.new(build_request_path("#{MACROMOLECULES_PATH}/#{CGI.escape(cid)}"))
    process_request(request)
  end

  private

  def build_request_path(sub_path)
    File.join(@uri.path, sub_path)
  end

  def process_request(request)
    if Rails.application.config.x.biomolecule_toolkit_api_key
      request['x-api-key'] = Rails.application.config.x.biomolecule_toolkit_api_key
    end
    request['Content-Type'] = 'application/json'
    response = @http.request(request)

    case response
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
