# frozen_string_literal: true

module ProtocolImporters
  class SearchProtocolsService
    extend Service

    attr_reader :errors, :protocols_list

    CONSTANTS = Constants::PROTOCOLS_IO_V3_API

    def initialize(protocol_source:, query_params: {})
      @protocol_source = protocol_source
      @query_params = query_params.except(:protocol_source)
      @errors = Hash.new { |h, k| h[k] = {} }
    end

    def call
      return self unless valid?

      # Call api client
      api_response = api_client.protocol_list(@query_params)

      # Normalize protocols list
      @protocols_list = normalizer.normalize_list(api_response)

      self
    rescue client_errors => e
      @errors[e.error_type] = e.message
      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      # try if page id is ok
      @errors[:invalid_params][:page_id] = 'Page needs to be positive' if @query_params[:page_id]&.to_i&.negative?

      # try if endpints exists
      @errors[:invalid_params][:source_endpoint] = 'Wrong source endpoint' unless endpoint_name.is_a?(String)

      succeed?
    end

    def endpoint_name
      Constants::PROTOCOLS_ENDPOINTS.dig(*@protocol_source.split('/').map(&:to_sym))
    end

    def api_client
      "ProtocolImporters::#{endpoint_name}::ApiClient".constantize.new
    end

    def normalizer
      "ProtocolImporters::#{endpoint_name}::ProtocolNormalizer".constantize.new
    end

    def client_errors
      "ProtocolImporters::#{endpoint_name}::Error".constantize
    end
  end
end
