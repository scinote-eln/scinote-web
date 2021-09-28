# frozen_string_literal: true

class UserRole < ApplicationRecord
  validate :prevent_update, on: :update, if: :predefined?
  validates :name,
            presence: true,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { case_sensitive: false }
  validates :permissions, presence: true, length: { minimum: 1 }
  validates :created_by, presence: true, unless: :predefined?
  validates :last_modified_by, presence: true, unless: :predefined?

  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :last_modified_by, class_name: 'User', optional: true
  has_many :user_assignments, dependent: :destroy

  def self.owner_role
    new(
      name: I18n.t('user_roles.predefined.owner'),
      permissions: PredefinedRoles::OWNER_PERMISSIONS,
      predefined: true
    )
  end

  def self.normal_user_role
    new(
      name: I18n.t('user_roles.predefined.normal_user'),
      permissions: PredefinedRoles::NORMAL_USER_PERMISSIONS,
      predefined: true
    )
  end

  def self.technician_role
    new(
      name: I18n.t('user_roles.predefined.technician'),
      permissions: PredefinedRoles::TECHNICIAN_PERMISSIONS,
      predefined: true
    )
  end

  def self.viewer_role
    new(
      name: I18n.t('user_roles.predefined.viewer'),
      permissions: PredefinedRoles::VIEWER_PERMISSIONS,
      predefined: true
    )
  end

  def owner?
    name == I18n.t('user_roles.predefined.owner')
  end

  private

  def prevent_update
    errors.add(:base, I18n.t('user_roles.predefined.unchangable_error_message'))
  end
end
