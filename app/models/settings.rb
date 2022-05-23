# frozen_string_literal: true

class Settings < ApplicationRecord
  def self.instance
    @instance = first || new
  end
end
