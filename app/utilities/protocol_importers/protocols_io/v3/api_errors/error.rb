# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIO
    module V3
      module ApiErrors
        class Error < StandardError
          attr_reader :status_code, :error_message

          def initialize(status_code, error_message)
            @status_code = status_code
            @error_message = error_message
          end
        end
      end
    end
  end
end
