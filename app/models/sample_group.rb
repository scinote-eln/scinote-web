class SampleGroup < ActiveRecord::Base
  auto_strip_attributes :name, :color, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :organization, case_sensitive: false }
  validates :color,
            presence: true,
            length: { maximum: Constants::COLOR_MAX_LENGTH }
  validates :organization, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :organization, inverse_of: :sample_groups
  has_many :samples, inverse_of: :sample_groups
end
