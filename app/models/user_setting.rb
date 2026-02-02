# frozen_string_literal: true

class UserSetting < ApplicationRecord
  belongs_to :user

  validates :key, format: /\A[a-z0-9]+(?:_[a-z0-9]+)*\z/
end
