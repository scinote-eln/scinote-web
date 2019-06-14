# frozen_string_literal: true

module ProtocolImporters
  class SearchProtocolsService
    extend Service

    attr_reader :errors, :protocols_list

    CONSTANTS = Constants::PROTOCOLS_IO_V3_API

    def initialize(protocol_source:, query_params: {})
      @protocol_source = protocol_source
      @query_params = query_params
      @errors = Hash.new { |h, k| h[k] = {} }
    end

    def call
      return self unless valid?

      api_response = api_client.protocol_list(@query_params)

      @protocols_list = normalizer.normalize_list(api_response)

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      # try if key is not empty
      @errors[:invalid_params][:key] = 'Key cannot be empty' if @query_params[:key].blank?

      # try if page id is ok
      if @query_params[:page_id] && !@query_params[:page_id].to_i.positive?
        @errors[:invalid_params][:page_id] = 'Page needs to be positive'
      end

      # try if order_field is ok
      if @query_params[:order_field] && CONSTANTS[:available_order_fields].exclude?(@query_params[:order_field]&.to_sym)
        @errors[:invalid_params][:order_field] = 'Order field is not ok'
      end

      # try if order dir is ok
      if @query_params[:order_field] && CONSTANTS[:available_order_dirs].exclude?(@query_params[:order_dir]&.to_sym)
        @errors[:invalid_params][:order_dir] = 'Order dir is not ok'
      end

      # try if endpints exists
      @errors[:invalid_params][:source_endpoint] = 'Wrong source endpoint' unless endpoint_name&.is_a?(String)

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
  end
end
