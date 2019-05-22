# frozen_string_literal: true

module ProtocolImporters
  class ProtocolImporter
    def load_protocols(_params: {})
      raise NotImplementedError
    end

    def load_single_protocol(_id:, _params: {})
      raise NotImplementedError
    end
  end
end
