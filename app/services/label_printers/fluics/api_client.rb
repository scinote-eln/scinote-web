# frozen_string_literal: true

module LabelPrinters
  module Fluics
    class ApiClient
      include HTTParty
      base_uri 'https://print-api.fluics.com/latest'

      def initialize(api_key)
        self.class.headers(
          'Accept' => 'application/json',
          'x-api-key' => api_key
        )
      end

      def list
        self.class.get('/get_printers_list')
      end

      def status(lid)
        self.class.get("/#{lid}/status")
      end

      def calibrate(lid)
        self.class.post("/#{lid}/calibrate")
      end

      def print(lid, zpl)
        self.class.post(
          "/#{lid}/print",
          headers: {
            'Content-Type' => 'text/plain'
          },
          body: zpl
        )
      end
    end
  end
end
