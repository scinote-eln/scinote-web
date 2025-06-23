# frozen_string_literal: true

class UserGroup < ApplicationRecord
  include SearchableModel

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

  accepts_nested_attributes_for :user_group_memberships

  def user_group_memberships_attributes=(attributes)
    attributes.each do |membership|
      membership[:created_by_id] = last_modified_by_id
      user_group_memberships.build(membership)
    end
  end

  def self.enabled?
    ApplicationSettings.instance.values['user_groups_enabled']
  end
end
