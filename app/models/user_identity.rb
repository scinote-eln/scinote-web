class UserIdentity < ActiveRecord::Base
  belongs_to :user
  validates :provider, uniqueness: { scope: :user_id }
end
