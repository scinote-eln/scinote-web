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
        ProjectPermissions::READ_ARCHIVED,
        ProjectPermissions::ACTIVITIES_READ,
        ProjectPermissions::USERS_READ,
        ProjectPermissions::COMMENTS_READ,
        ProjectPermissions::COMMENTS_CREATE,
        ProjectPermissions::EXPERIMENTS_CREATE,
        ExperimentPermissions::READ,
        ExperimentPermissions::MANAGE,
        ExperimentPermissions::TASKS_MANAGE,
        MyModulePermissions::READ,
        MyModulePermissions::MANAGE,
        MyModulePermissions::RESULTS_MANAGE,
        MyModulePermissions::PROTOCOL_MANAGE,
        MyModulePermissions::STEPS_MANAGE,
        MyModulePermissions::TAGS_MANAGE,
        MyModulePermissions::COMMENTS_CREATE,
        MyModulePermissions::COMMENTS_MANAGE,
        MyModulePermissions::COMMENTS_MANAGE_OWN,
        MyModulePermissions::COMPLETE,
        MyModulePermissions::UPDATE_STATUS,
        MyModulePermissions::STEPS_COMPLETE,
        MyModulePermissions::STEPS_UNCOMPLETE,
        MyModulePermissions::STEPS_CHECKLIST_CHECK,
        MyModulePermissions::STEPS_CHECKLIST_UNCHECK,
        MyModulePermissions::STEPS_COMMENTS_CREATE,
        MyModulePermissions::STEPS_COMMENTS_DELETE_OWN,
        MyModulePermissions::STEPS_COMMENT_UPDATE_OWN,
        MyModulePermissions::REPOSITORY_ROWS_ASSIGN,
        MyModulePermissions::REPOSITORY_ROWS_MANAGE
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
        ProjectPermissions::READ_ARCHIVED,
        ProjectPermissions::ACTIVITIES_READ,
        ProjectPermissions::USERS_READ,
        ProjectPermissions::COMMENTS_READ,
        ProjectPermissions::COMMENTS_CREATE,
        ExperimentPermissions::READ,
        ExperimentPermissions::READ_ARCHIVED,
        ExperimentPermissions::ACTIVITIES_READ,
        ExperimentPermissions::USERS_READ,
        MyModulePermissions::READ,
        MyModulePermissions::COMMENTS_CREATE,
        MyModulePermissions::COMMENTS_MANAGE_OWN,
        MyModulePermissions::COMPLETE,
        MyModulePermissions::UPDATE_STATUS,
        MyModulePermissions::STEPS_COMPLETE,
        MyModulePermissions::STEPS_UNCOMPLETE,
        MyModulePermissions::STEPS_CHECKLIST_CHECK,
        MyModulePermissions::STEPS_CHECKLIST_UNCHECK,
        MyModulePermissions::STEPS_COMMENTS_CREATE,
        MyModulePermissions::STEPS_COMMENTS_DELETE_OWN,
        MyModulePermissions::STEPS_COMMENT_UPDATE_OWN,
        MyModulePermissions::REPOSITORY_ROWS_ASSIGN,
        MyModulePermissions::REPOSITORY_ROWS_MANAGE
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
        ProjectPermissions::READ_ARCHIVED,
        ProjectPermissions::ACTIVITIES_READ,
        ProjectPermissions::USERS_READ,
        ProjectPermissions::COMMENTS_READ,
        ExperimentPermissions::READ,
        ExperimentPermissions::READ_ARCHIVED,
        ExperimentPermissions::ACTIVITIES_READ,
        ExperimentPermissions::USERS_READ,
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
    errors.add(:base, I18n.t('user_roles.predefined.unchangable_error_message'))
  end
end
