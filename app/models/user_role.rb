# frozen_string_literal: true

class UserRole < ApplicationRecord
  before_update :prevent_update, if: :predefined?

  validates :name,
            presence: true,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { case_sensitive: false }
  validates :permissions, presence: true, length: { minimum: 1 }
  validates :created_by, presence: true, unless: :predefined?
  validates :last_modified_by, presence: true, unless: :predefined?

  belongs_to :created_by, foreign_key: 'created_by_id', class_name: 'User', optional: true
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  has_many :user_assignments, dependent: :destroy

  def self.owner_role
    new(
      name: I18n.t('user_roles.predefined.owner'),
      permissions: ProjectPermissions.constants.map { |const| ProjectPermissions.const_get(const) } +
                   ExperimentPermissions.constants.map { |const| ExperimentPermissions.const_get(const) } +
                   MyModulePermissions.constants.map { |const| MyModulePermissions.const_get(const) },
      predefined: true
    )
  end

  def self.normal_user_role
    new(
      name: I18n.t('user_roles.predefined.normal_user'),
      permissions:
      [
        ProjectPermissions::READ,
        ProjectPermissions::EXPERIMENTS_CREATE,
        ProjectPermissions::COMMENTS_CREATE,
        ExperimentPermissions::READ,
        ExperimentPermissions::MANAGE,
        ExperimentPermissions::ARCHIVE,
        ExperimentPermissions::RESTORE,
        ExperimentPermissions::CLONE,
        ExperimentPermissions::CREATE_TASKS,
        MyModulePermissions::READ,
        MyModulePermissions::CREATE_COMMENTS,
        MyModulePermissions::ASSIGN_REPOSITORY_ROWS,
        MyModulePermissions::CHANGE_FLOW_STATUS,
        MyModulePermissions::CREATE_REPOSITORY_SNAPSHOT,
        MyModulePermissions::MANAGE_REPOSITORY_SNAPSHOT
      ],
      predefined: true
    )
  end

  def self.technician_role
    new(
      name: I18n.t('user_roles.predefined.technician'),
      permissions:
      [
        ProjectPermissions::READ,
        ProjectPermissions::COMMENTS_CREATE,
        ExperimentPermissions::READ,
        MyModulePermissions::READ,
        MyModulePermissions::CREATE_COMMENTS,
        MyModulePermissions::ASSIGN_REPOSITORY_ROWS,
        MyModulePermissions::CHANGE_FLOW_STATUS,
        MyModulePermissions::CREATE_REPOSITORY_SNAPSHOT,
        MyModulePermissions::MANAGE_REPOSITORY_SNAPSHOT
      ],
      predefined: true
    )
  end

  def self.viewer_role
    new(
      name: I18n.t('user_roles.predefined.viewer'),
      permissions:
      [
        ProjectPermissions::READ,
        ExperimentPermissions::READ,
        MyModulePermissions::READ
      ],
      predefined: true
    )
  end

  def owner?
    name == I18n.t('user_roles.predefined.owner')
  end

  private

  def prevent_update
    raise ActiveRecord::RecordInvalid, I18n.t('user_roles.predefined.unchangable_error_message')
  end
end
