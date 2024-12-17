# frozen_string_literal: true

class Form < ApplicationRecord
  ID_PREFIX = 'FR'
  include PrefixedIdModel
  include ArchivableModel
  include PermissionCheckableModel
  include Assignable

  belongs_to :team
  belongs_to :parent, class_name: 'Form', optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'
  belongs_to :published_by, class_name: 'User', optional: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true
  belongs_to :default_public_user_role, class_name: 'UserRole', optional: true

  has_many :form_fields, inverse_of: :form, dependent: :destroy
  has_many :users, through: :user_assignments

  validates :name, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::NAME_MAX_LENGTH }

  after_create :update_automatic_user_assignments, if: -> { visible? }
  before_update :change_visibility, if: :default_public_user_role_id_changed?
  after_update :update_automatic_user_assignments,
               if: -> { saved_change_to_default_public_user_role_id? }

  enum visibility: { hidden: 0, visible: 1 }

  def permission_parent
    nil
  end

  def published?
    published_on.present?
  end

  def create_or_update_public_user_assignments!(assigned_by)
    public_role = default_public_user_role || UserRole.find_predefined_viewer_role
    team.user_assignments.where.not(user: assigned_by).find_each do |team_user_assignment|
      new_user_assignment = user_assignments.find_or_initialize_by(user: team_user_assignment.user)
      next if new_user_assignment.manually_assigned?

      new_user_assignment.user_role = public_role
      new_user_assignment.assigned_by = assigned_by
      new_user_assignment.assigned = :automatically
      new_user_assignment.save!
    end
  end

  private

  def update_automatic_user_assignments
    return if skip_user_assignments

    case visibility
    when 'visible'
      create_or_update_public_user_assignments!(last_modified_by)
    when 'hidden'
      automatic_user_assignments.where.not(user: last_modified_by).destroy_all
    end
  end

  def change_visibility
    self.visibility = default_public_user_role_id.present? ? :visible : :hidden
  end
end
