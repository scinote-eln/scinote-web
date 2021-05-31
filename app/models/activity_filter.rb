# frozen_string_literal: true

class ActivityFilter < ApplicationRecord
  validates :name, presence: true
  validates :filter, presence: true
end
