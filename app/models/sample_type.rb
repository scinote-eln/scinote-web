# frozen_string_literal: true

class SampleType < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team_id, case_sensitive: false }
  validates :team, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  belongs_to :team, inverse_of: :sample_types
  has_many :samples, inverse_of: :sample_types

  scope :sorted, -> { order(name: :asc) }
end
