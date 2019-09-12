# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIo
    module V3
      # InvalidToken, ExpiredToken
      class UnauthorizedError < Error; end
    end
  end
end
