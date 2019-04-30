# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIO
    module V3
      class ApiClient
        include HTTParty

        CONSTANTS = Constants::PROTOCOLS_IO_V3_API

        base_uri CONSTANTS[:base_uri]
        default_timeout CONSTANTS[:default_timeout]
        logger Rails.logger, CONSTANTS[:debug_level]

        def initialize(token = nil)
          # Currently we support public tokens only (no token needed for public data)
          @auth = { token: token }

          # Set default headers
          self.class.headers('Authorization': "Bearer #{@auth[:token]}") if @auth[:token].present?
        end

        # Query params available are:
        #   filter (optional): {public|user_public|user_private|shared_with_user}
        #     Which type of protocols to filter.
        #     default is public and requires no auth token.
        #     user_public requires public token.
        #     user_private|shared_with_user require private auth token.
        #   key (optional): string
        #     Search key to search for in protocol name, description, authors.
        #     default: ''
        #   order_field (optional): {activity|date|name|id}
        #     order by this field.
        #     default is activity.
        #   order_dir (optional): {desc|asc}
        #     Direction of ordering.
        #     default is desc.
        #   page_size (optional): int
        #     Number of items per page.
        #     Default 10.
        #   page_id (optional): int (1..n)
        #     id of page.
        #     Default is 1.
        def protocol_list(query_params = {})
          query = CONSTANTS.dig(:endpoints, :protocols, :default_query_params)
                           .merge(query_params)

          self.class.get('/protocols', query: query)
        end

        # Returns full representation of given protocol ID
        def single_protocol(id)
          self.class.get("/protocols/#{id}")
        end

        # Returns html preview for given protocol
        # This endpoint is outside the scope of API but is listed here for the
        # sake of clarity
        def protocol_html_preview(uri)
          self.class.get("https://www.protocols.io/view/#{uri}.html", headers: {})
        end
      end
    end
  end
end
