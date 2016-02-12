class CustomField < ActiveRecord::Base
  validates :name,
    presence: true,
    length: { maximum: 50 }
  validates :user, :organization, presence: true

  belongs_to :user, inverse_of: :custom_fields
  belongs_to :organization, inverse_of: :custom_fields
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'
  has_many :sample_custom_fields, inverse_of: :custom_field
end
