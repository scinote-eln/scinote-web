# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIO
    module V3
      module V3Errors
        class Error < StandardError
          attr_reader :error_type

          def initialize(error_type)
            @error_type = error_type
          end
        end
      end
    end
  end
end
