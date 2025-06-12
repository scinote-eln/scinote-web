# frozen_string_literal: true

class UserGroupMembership < ApplicationRecord
  belongs_to :user_group
  belongs_to :user
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'

  validates :user, uniqueness: { scope: :user_group }
end
