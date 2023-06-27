# frozen_string_literal: true

module Protocols
  class DocxImportJob < ApplicationJob
    def perform(files)
      ProtocolImporters::DocxService.new(files).call
    end
  end
end
