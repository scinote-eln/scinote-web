# frozen_string_literal: true

class UserGroupMembership < ApplicationRecord
  include SearchableModel

  belongs_to :user_group
  belongs_to :user
  belongs_to :created_by, class_name: 'User'

  validates :user, uniqueness: { scope: :user_group }
end
