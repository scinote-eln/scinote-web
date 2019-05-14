# frozen_string_literal: true

module ProtocolImporters
  class ProtocolNormalizer
    def load_all_protocols(_params: {})
      raise NotImplementedError
    end

    def load_protocol(_id:, _params: {})
      raise NotImplementedError
    end
  end
end
