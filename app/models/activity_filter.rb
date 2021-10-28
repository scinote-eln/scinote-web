# frozen_string_literal: true

class ActivityFilter < ApplicationRecord
  validates :name, presence: true
  validates :filter, presence: true

  has_many :webhooks, dependent: :destroy
end
