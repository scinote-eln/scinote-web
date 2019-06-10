# frozen_string_literal: true

module ProtocolImporters
  class ProtocolNormalizer
    def normalize_all_protocols(client_data)
      raise NotImplementedError
    end

    def normalize_protocol(client_data)
      raise NotImplementedError
    end
  end
end
