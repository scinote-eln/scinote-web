# frozen_string_literal: true

module ProtocolImporters
  class ProtocolNormalizer
    def normalize_list(_client_data)
      raise NotImplementedError
    end

    def normalize_protocol(_client_data)
      raise NotImplementedError
    end
  end
end
