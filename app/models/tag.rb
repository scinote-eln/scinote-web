# frozen_string_literal: true

class Tag < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, :color, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :color,
            presence: true,
            length: { maximum: Constants::COLOR_MAX_LENGTH }

  belongs_to :team
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true
  has_many :taggings, dependent: :destroy

  before_validation -> { self.color = Constants::TAG_COLORS.sample.to_s }, if: -> { color.blank? }
end
