# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIO
    module V3
      module V3Errors
        class UnauthorizedError < Error
          # InvalidToken, ExpiredToken
        end
      end
    end
  end
end
