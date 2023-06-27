# frozen_string_literal: true

module ProtocolImporters
  class DocxService
    def initialize(files)
      @files = files
    end

    def call
      # TODO: Implement actual logic
      raise StandardError if rand(100) > 70
    end
  end
end
