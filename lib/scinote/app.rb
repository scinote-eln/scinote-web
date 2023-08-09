# frozen_string_literal: true

module Scinote
  module App
    mattr_accessor :pendo_enabled
    self.pendo_enabled = ''

    mattr_accessor :pendo_id
    self.pendo_id = ''

    def self.setup
      yield self
    end
  end
end
