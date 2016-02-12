class SampleGroup < ActiveRecord::Base
  validates :name,
    presence: true,
    length: { maximum: 50 }
  validates :color,
    presence: true,
    length: { maximum: 7 }
  validates :organization, presence: true

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User'
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  belongs_to :organization, inverse_of: :sample_groups
  has_many :samples, inverse_of: :sample_groups
end
