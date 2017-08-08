class UserIdentity < ApplicationRecord
  belongs_to :user
  validates :provider, uniqueness: { scope: :user_id }
end
