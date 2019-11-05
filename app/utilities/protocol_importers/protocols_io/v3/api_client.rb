# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIo
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
          local_sorting = false
          response = with_handle_network_errors do
            sort_mappings = CONSTANTS[:sort_mappings]
            query = CONSTANTS.dig(:endpoints, :protocols, :default_query_params)
                             .stringify_keys
                             .merge(query_params.except(:sort_by).stringify_keys)

            if sort_mappings[query_params[:sort_by]&.to_sym]
              query = query.merge(sort_mappings[query_params[:sort_by].to_sym].stringify_keys)
            end

            # If key is blank access show latest publications, otherwise use
            # normal endpoint
            if query['key'].blank?
              local_sorting = true
              query = CONSTANTS.dig(:endpoints, :publications, :default_query_params)
              self.class.get('/publications', query: query)
            else
              self.class.get('/protocols', query: query)
            end
          end
          check_for_response_errors(response)
          if local_sorting && %w(alpha_asc alpha_desc newest oldest).include?(query_params[:sort_by])
            response.parsed_response[:local_sorting] = query_params[:sort_by]
          end
          response
        end

        # Returns full representation of given protocol ID
        def single_protocol(id)
          response = with_handle_network_errors do
            self.class.get("/protocols/#{id}")
          end
          check_for_response_errors(response)
        end

        # Returns html preview for given protocol
        # This endpoint is outside the scope of API but is listed here for the
        # sake of clarity
        def protocol_html_preview(uri)
          with_handle_network_errors do
            self.class.get("https://www.protocols.io/view/#{uri}.html", headers: {})
          end
        end

        private

        def with_handle_network_errors
          yield
        rescue StandardError => e
          Rails.logger.error "Error: #{e.class}, message: #{e.message}"

          raise ProtocolImporters::ProtocolsIo::V3::NetworkError.new(e.class),
                I18n.t('protocol_importers.errors.cannot_import_protocol')
        end

        def check_for_response_errors(response)
          error_message = response.parsed_response['error_message']

          case response.parsed_response['status_code']
          when 0
            return response
          when 1
            raise ProtocolImporters::ProtocolsIo::V3::ArgumentError.new(:missing_or_empty_parameters), error_message
          when 1218
            raise ProtocolImporters::ProtocolsIo::V3::UnauthorizedError.new(:invalid_token), error_message
          when 1219
            raise ProtocolImporters::ProtocolsIo::V3::UnauthorizedError.new(:token_expires), error_message
          else
            raise ProtocolImporters::ProtocolsIo::V3::Error.new(:api_response_error), response.parsed_response
          end
        end
      end
    end
  end
end
