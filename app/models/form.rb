# frozen_string_literal: true

class Form < ApplicationRecord
  ID_PREFIX = 'FR'
  include PrefixedIdModel
  include ArchivableModel
  include PermissionCheckableModel
  include Assignable
  include SearchableModel
  include SearchableByNameModel
  include Cloneable

  SEARCHABLE_ATTRIBUTES = ['forms.name'].freeze

  belongs_to :team
  belongs_to :parent, class_name: 'Form', optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'
  belongs_to :published_by, class_name: 'User', optional: true
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true

  has_many :form_fields, -> { order(:position) }, inverse_of: :form, dependent: :destroy
  has_many :form_responses, dependent: :destroy
  has_many :users, through: :user_assignments

  scope :published, -> { where.not(published_on: nil) }

  validates :name, length: { minimum: Constants::NAME_MIN_LENGTH, maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::NAME_MAX_LENGTH }

  enum :visibility, { hidden: 0, visible: 1 }

  def self.viewable_by_user(user, teams)
    # Team owners see all forms in the team
    owner_role = UserRole.find_predefined_owner_role
    forms = Form.where(team: teams)
    viewable_as_team_owner = forms.joins("INNER JOIN user_assignments team_user_assignments " \
                                         "ON team_user_assignments.assignable_type = 'Team' " \
                                         "AND team_user_assignments.assignable_id = forms.team_id")
                                  .where(team_user_assignments: { user_id: user, user_role_id: owner_role })
                                  .select(:id)
    viewable_as_assigned = forms.with_granted_permissions(user, FormPermissions::READ).select(:id)

    where('forms.id IN ((?) UNION (?))', viewable_as_team_owner, viewable_as_assigned)
  end

  def archived_branch?
    archived?
  end

  def unused?
    form_responses.none?
  end

  def permission_parent
    nil
  end

  def published?
    published_on.present?
  end

  def self.forms_enabled?
    ApplicationSettings.instance.values['forms_enabled'] == true
  end

  def duplicate!(user = nil)
    new_form = dup
    new_form.name = next_clone_name
    new_form.created_by = user || created_by
    new_form.last_modified_by = user || last_modified_by
    new_form.published_by = nil
    new_form.published_on = nil
    new_form.save!

    form_fields.each do |form_field|
      new_form_field = form_field.dup
      new_form_field.form = new_form
      new_form_field.created_by = user || created_by
      new_form_field.save!
    end

    new_form
  end
end
