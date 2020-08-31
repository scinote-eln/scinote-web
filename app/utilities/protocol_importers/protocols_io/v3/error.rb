# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIo
    module V3
      class Error < StandardError
        attr_reader :error_type

        def initialize(error_type)
          @error_type = error_type
        end
      end

      # MissingOrEmptyParameters
      class ArgumentError < Error; end

      # SocketError, HTTPParty::Error
      class NetworkError < Error; end

      # InvalidToken, ExpiredToken
      class UnauthorizedError < Error; end

      # General NormalizerError
      class NormalizerError < Error; end
    end
  end
end
