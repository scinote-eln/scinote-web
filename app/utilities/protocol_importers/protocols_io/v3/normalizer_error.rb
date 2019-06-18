# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIO
    module V3
      class NormalizerError < StandardError
        attr_reader :error_type, :error_message

        def initialize(error_type, error_message)
          @error_type = error_type
          @error_message = error_message
        end
      end
    end
  end
end
