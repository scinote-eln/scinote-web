# frozen_string_literal: true

module Protocols
  class DocxImportJob < ApplicationJob
    def perform(files, user)
      ProtocolImporters::DocxService.new(files, user).import!
    end
  end
end
