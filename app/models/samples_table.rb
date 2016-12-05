class SamplesTable < ActiveRecord::Base
  validates :user, :organization, presence: true

  belongs_to :user, inverse_of: :samples_tables
  belongs_to :organization, inverse_of: :samples_tables

  scope :find_status,
        ->(org, user) { where(user: user, organization: org).pluck(:status) }
end
