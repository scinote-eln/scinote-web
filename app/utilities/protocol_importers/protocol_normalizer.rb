# frozen_string_literal: true

module ProtocolImporters
  class ProtocolNormalizer
    def load_all_protocols(api_response)
      raise NotImplementedError
    end

    def load_protocol(api_response)
      raise NotImplementedError
    end
  end
end
