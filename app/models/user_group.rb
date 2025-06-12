# frozen_string_literal: true

class UserGroup < ApplicationRecord
  validates :name,
            presence: true,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team_id, case_sensitive: false }

  belongs_to :team
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true
  has_many :user_group_memberships, dependent: :destroy
  has_many :users, through: :user_group_memberships, dependent: :destroy
end
