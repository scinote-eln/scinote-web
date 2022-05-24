# frozen_string_literal: true

class Settings < ApplicationRecord
  def self.instance
    first || new
  end
end
