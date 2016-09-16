class CustomField < ActiveRecord::Base
  validates :name,
    presence: true,
    length: { maximum: NAME_MAX_LENGTH },
    uniqueness: { scope: :organization, case_sensitive: true},
    exclusion: {in: ["Assigned", "Sample name", "Sample type", "Sample group", "Added on", "Added by"]}
  validates :user, :organization, presence: true

  belongs_to :user, inverse_of: :custom_fields
  belongs_to :organization, inverse_of: :custom_fields
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  has_many :sample_custom_fields, inverse_of: :custom_field
end
