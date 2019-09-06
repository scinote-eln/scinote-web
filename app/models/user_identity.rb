# frozen_string_literal: true

class UserIdentity < ActiveRecord::Base
  belongs_to :user
  validates :provider, presence: true, uniqueness: { scope: :user_id }
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
