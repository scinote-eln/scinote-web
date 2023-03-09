# frozen_string_literal: true

module LabelPrinters
  module Fluics
    class ApiClient
      class NotFoundError < StandardError; end

      class ServerError < StandardError; end

      class BadRequestError < StandardError; end

      include HTTParty
      base_uri 'https://print-api.fluics.com/v3'

      def initialize(api_key)
        self.class.headers(
          'Accept' => 'application/json',
          'x-api-key' => api_key
        )
      end

      def list
        do_request(:get, '/get_printers_list')
      end

      def status(lid)
        do_request(:get, "/#{lid}/status")
      end

      def calibrate(lid)
        do_request(:post, "/#{lid}/calibrate")
      end

      def print(lid, zpl)
        do_request(
          :post,
          "/#{lid}/print",
          params: {
            headers: { 'Content-Type' => 'text/plain' },
            body: zpl
          }
        )
      end

      def list_templates
        group_name = ENV['FLUICS_TEMPLATES_GROUP'] || ''
        do_request(:get, '/get_templates', params: { query: { templateGroups: group_name } })
      end

      private

      def do_request(http_method, path, params: {})
        response = self.class.public_send(http_method, path, params)

        case response.code
        when 200..299
          # success response
        when 404
          raise NotFoundError, "#{response.code}: #{response.message}"
        when 400..499
          raise BadRequestError, "#{response.code}: #{response.message}"
        when 500...600
          raise ServerError, "#{response.code}: #{response.message}"
        end

        response
      end
    end
  end
end
