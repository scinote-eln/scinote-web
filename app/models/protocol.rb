# frozen_string_literal: true

class Protocol < ApplicationRecord
  ID_PREFIX = 'PT'

  include ArchivableModel
  include PrefixedIdModel
  SEARCHABLE_ATTRIBUTES = ['protocols.name', 'protocols.description',
                           'protocols.authors', 'protocol_keywords.name', PREFIXED_ID_SQL].freeze

  include SearchableModel
  include RenamingUtil
  include SearchableByNameModel
  include Assignable
  include PermissionCheckableModel
  include TinyMceImages

  before_validation :assign_version_number, on: :update, if: -> { protocol_type_changed? && in_repository_published? }
  after_update :update_user_assignments, if: -> { saved_change_to_protocol_type? && in_repository? }
  after_destroy :decrement_linked_children
  after_save :update_linked_children
  after_create :auto_assign_protocol_members, if: :visible?
  skip_callback :create, :after, :create_users_assignments, if: -> { in_module? }

  enum visibility: { hidden: 0, visible: 1 }
  enum protocol_type: {
    unlinked: 0,
    linked: 1,
    in_repository_published_original: 2,
    in_repository_draft: 3,
    in_repository_published_version: 4
  }

  auto_strip_attributes :name, :description, nullify: false
  # Name is required when its actually specified (i.e. :in_repository? is true)
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :team, presence: true
  validates :protocol_type, presence: true
  validate :prevent_update,
           on: :update,
           if: lambda {
             in_repository_published? && !protocol_type_changed?(from: 'in_repository_draft') && !archived_changed?
           }

  with_options if: :in_module? do
    validates :my_module, presence: true
    validates :archived_by, absence: true
    validates :archived_on, absence: true
  end
  with_options if: :linked? do
    validate :linked_parent_type_constrain
    validates :added_by, presence: true
    validates :parent, presence: true
    validates :parent_updated_at, presence: true
  end
  with_options if: :in_repository? do
    validates :name, presence: true
    validates :added_by, presence: true
    validates :my_module, absence: true
    validates :parent_updated_at, absence: true
  end
  with_options if: :in_repository_published_version? do
    validates :parent, presence: true
    validate :versions_same_name_constrain
  end
  with_options if: :in_repository_draft? do
    # Only one draft can exist for each protocol
    validates :parent_id, uniqueness: { scope: :protocol_type }, if: -> { parent_id.present? }
    validate :versions_same_name_constrain
  end
  with_options if: -> { in_repository? && active? && !parent } do |protocol|
    # Active protocol must have unique name inside its team
    protocol
      .validates_uniqueness_of :name, case_sensitive: false,
                               scope: :team,
                               conditions: lambda {
                                 active.where(
                                   protocol_type: [
                                     Protocol.protocol_types[:in_repository_published_original],
                                     Protocol.protocol_types[:in_repository_draft]
                                   ]
                                 )
                               }
  end
  with_options if: -> { in_repository? && archived? && !previous_version } do |protocol|
    # Archived protocol must have unique name inside its team
    protocol
      .validates_uniqueness_of :name, case_sensitive: false,
                               scope: :team,
                               conditions: lambda {
                                 archived.where(
                                   protocol_type: [
                                     Protocol.protocol_types[:in_repository_published_original],
                                     Protocol.protocol_types[:in_repository_draft]
                                   ]
                                 )
                               }
    protocol.validates :archived_by, presence: true
    protocol.validates :archived_on, presence: true
  end

  belongs_to :added_by,
             class_name: 'User',
             inverse_of: :added_protocols,
             optional: true
  belongs_to :last_modified_by,
             class_name: 'User',
             optional: true
  belongs_to :my_module,
             inverse_of: :protocols,
             optional: true
  belongs_to :team, inverse_of: :protocols
  belongs_to :default_public_user_role,
             class_name: 'UserRole',
             optional: true
  belongs_to :previous_version,
             class_name: 'Protocol',
             inverse_of: :next_version,
             optional: true
  belongs_to :parent,
             class_name: 'Protocol',
             optional: true
  belongs_to :archived_by,
             class_name: 'User',
             inverse_of: :archived_protocols, optional: true
  belongs_to :restored_by,
             class_name: 'User',
             inverse_of: :restored_protocols, optional: true
  belongs_to :published_by,
             class_name: 'User',
             inverse_of: :published_protocols, optional: true
  has_many :linked_children,
           class_name: 'Protocol',
           foreign_key: 'parent_id'
  has_one  :next_version,
           class_name: 'Protocol',
           foreign_key: 'previous_version_id',
           inverse_of: :previous_version,
           dependent: :destroy
  has_many :protocol_protocol_keywords,
           inverse_of: :protocol,
           dependent: :destroy
  has_many :protocol_keywords, through: :protocol_protocol_keywords
  has_many :steps, inverse_of: :protocol, dependent: :destroy

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    team_ids = Team.joins(:user_teams)
                   .where(user_teams: { user_id: user.id })
                   .distinct
                   .pluck(:id)

    module_ids = MyModule.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
                         .pluck(:id)

    where_str =
      '(protocol_type IN (?) AND my_module_id IN (?)) OR ' \
      '(protocol_type = ? AND protocols.team_id IN (?) AND ' \
      'added_by_id = ?) OR (protocol_type = ? AND protocols.team_id IN (?))'

    if include_archived
      where_str +=
        ' OR (protocol_type = ? AND protocols.team_id IN (?) ' \
        'AND added_by_id = ?)'
      new_query = Protocol
                  .where(
                    where_str,
                    [Protocol.protocol_types[:unlinked],
                     Protocol.protocol_types[:linked]],
                    module_ids,
                    Protocol.protocol_types[:in_repository_private],
                    team_ids,
                    user.id,
                    Protocol.protocol_types[:in_repository_public],
                    team_ids,
                    Protocol.protocol_types[:in_repository_archived],
                    team_ids,
                    user.id
                  )
    else
      new_query = Protocol
                  .where(
                    where_str,
                    [Protocol.protocol_types[:unlinked],
                     Protocol.protocol_types[:linked]],
                    module_ids,
                    Protocol.protocol_types[:in_repository_private],
                    team_ids,
                    user.id,
                    Protocol.protocol_types[:in_repository_public],
                    team_ids
                  )
    end

    new_query = new_query
                .distinct
                .joins('LEFT JOIN protocol_protocol_keywords ON ' \
                       'protocols.id = protocol_protocol_keywords.protocol_id')
                .joins('LEFT JOIN protocol_keywords ' \
                       'ON protocol_keywords.id = ' \
                       'protocol_protocol_keywords.protocol_keyword_id')
                .where_attributes_like(SEARCHABLE_ATTRIBUTES, query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.viewable_by_user(user, teams)
    where(my_module: MyModule.viewable_by_user(user, teams))
      .or(where(team: teams)
            .where('protocol_type = 3 OR '\
                   '(protocol_type = 2 AND added_by_id = :user_id)',
                   user_id: user.id))
  end


  def self.filter_by_teams(teams = [])
    teams.blank? ? self : where(team: teams)
  end

  def insert_step(step, position)
    ActiveRecord::Base.transaction do
      steps.where('position >= ?', position).desc_order.each do |s|
        s.update!(position: s.position + 1)
      end
      step.position = position
      step.protocol = self
      step.save!
    end
    step
  end

  def created_by
    in_module? ? my_module.created_by : added_by
  end

  def draft
    return nil unless in_repository_published_original?

    team.protocols.in_repository_draft.find_by(parent: self)
  end

  def published_versions
    return self.class.none unless in_repository_published_original?

    team.protocols
        .in_repository_published_version
        .where(parent: self)
        .or(team.protocols.in_repository_published_original.where(id: id))
  end

  def latest_published_version
    published_versions.order(version_number: :desc).first
  end

  def permission_parent
    in_module? ? my_module : team
  end

  def linked_modules
    MyModule.joins(:protocols).where('protocols.parent_id = ?', id)
  end

  def linked_experiments(linked_mod)
    Experiment.where('id IN (?)', linked_mod.pluck(:experiment_id).uniq)
  end

  def linked_projects(linked_exp)
    Project.where('id IN (?)', linked_exp.pluck(:project_id).uniq)
  end

  def self.new_blank_for_module(my_module)
    Protocol.new(
      team: my_module.experiment.project.team,
      protocol_type: :unlinked,
      my_module: my_module
    )
  end

  # Deep-clone given array of assets
  def self.deep_clone_assets(assets_to_clone)
    ActiveRecord::Base.no_touching do
      assets_to_clone.each do |src_id, dest_id|
        src = Asset.find_by(id: src_id)
        dest = Asset.find_by(id: dest_id)
        dest.destroy! if src.blank? && dest.present?
        next unless src.present? && dest.present?

        # Clone file
        src.duplicate_file(dest)
      end
    end
  end

  def self.clone_contents(src, dest, current_user, clone_keywords, only_contents = false)
    dest.update(description: src.description, name: src.name) unless only_contents

    src.clone_tinymce_assets(dest, dest.team)

    # Update keywords
    if clone_keywords
      src.protocol_keywords.each do |keyword|
        ProtocolProtocolKeyword.create(
          protocol: dest,
          protocol_keyword: keyword
        )
      end
    end

    # Copy steps
    src.steps.each do |step|
      step.duplicate(dest, current_user, step_position: step.position)
    end
  end

  def in_repository_active?
    in_repository? && active?
  end

  def in_repository?
    in_repository_published? || in_repository_draft?
  end

  def in_repository_published?
    in_repository_published_original? || in_repository_published_version?
  end

  def in_module?
    unlinked? || linked?
  end

  def linked_no_diff?
    linked? &&
      updated_at == parent_updated_at &&
      parent.updated_at == parent_updated_at
  end

  def newer_than_parent?
    linked? && parent.updated_at == parent_updated_at &&
      updated_at > parent_updated_at
  end

  def parent_newer?
    linked? &&
      updated_at == parent_updated_at &&
      parent.updated_at > parent_updated_at
  end

  def parent_and_self_newer?
    linked? &&
      parent.updated_at > parent_updated_at &&
      updated_at > parent_updated_at
  end

  def number_of_steps
    steps.count
  end

  def completed_steps
    steps.where(completed: true)
  end

  def first_step_id
    steps.find_by(position: 0)&.id
  end

  def space_taken
    st = 0
    steps.find_each do |step|
      st += step.space_taken
    end
    st
  end

  def make_private(user)
    # Don't update "updated_at" timestamp
    self.record_timestamps = false

    self.added_by = user
    self.published_on = nil
    self.archived_by = nil
    self.archived_on = nil
    self.restored_by = nil
    self.restored_on = nil
    self.protocol_type = Protocol.protocol_types[:in_repository_private]
    result = save

    if result
      Activities::CreateActivityService
        .call(activity_type: :move_protocol_in_repository,
              owner: user,
              subject: self,
              team: team,
              message_items: {
                protocol: id,
                storage: I18n.t('activities.protocols.team_to_my_message')
              })
    end
    result
  end

  def archive(user)
    return nil unless can_destroy?
    # We keep published_on present, so we know (upon restoring)
    # where the protocol was located

    self.archived_by = user
    self.archived_on = Time.now
    self.restored_by = nil
    self.restored_on = nil
    self.archived = true
    result = save

    # Update all module protocols that had
    # parent set to this protocol
    if result
      Activities::CreateActivityService
        .call(activity_type: :archive_protocol_in_repository,
              owner: user,
              subject: self,
              team: team,
              message_items: {
                protocol: id
              })
    end
    result
  end

  def restore(user)
    self.archived_by = nil
    self.archived_on = nil
    self.restored_by = user
    self.restored_on = Time.now
    self.archived = false

    result = save

    if result
      Activities::CreateActivityService
        .call(activity_type: :restore_protocol_in_repository,
              owner: user,
              subject: self,
              team: team,
              message_items: {
                protocol: id
              })
    end
    result
  end

  def update_keywords(keywords)
    result = true
    begin
      Protocol.transaction do
        self.record_timestamps = false

        # First, destroy all keywords
        protocol_protocol_keywords.destroy_all
        if keywords.present?
          keywords.each do |kw_name|
            kw = ProtocolKeyword.find_or_create_by(name: kw_name, team: team)
            protocol_keywords << kw
          end
        end
      end
    rescue StandardError
      result = false
    end
    result
  end

  def unlink
    self.parent = nil
    self.parent_updated_at = nil
    self.protocol_type = Protocol.protocol_types[:unlinked]
    save!
  end

  def update_parent(current_user)
    ActiveRecord::Base.no_touching do
      # First, destroy parent's step contents
      parent.destroy_contents
      parent.reload

      # Now, clone step contents
      Protocol.clone_contents(self, parent, current_user, false)
    end

    # Lastly, update the metadata
    parent.reload
    parent.record_timestamps = false
    parent.updated_at = updated_at
    parent.save!
    self.record_timestamps = false
    self.parent_updated_at = updated_at
    save!
  end

  def update_from_parent(current_user)
    ActiveRecord::Base.no_touching do
      # First, destroy step contents
      destroy_contents

      # Now, clone parent's step contents
      Protocol.clone_contents(parent, self, current_user, false)
    end

    # Lastly, update the metadata
    reload
    self.record_timestamps = false
    self.updated_at = parent.updated_at
    self.parent_updated_at = parent.updated_at
    self.added_by = current_user
    save!
  end

  def load_from_repository(source, current_user)
    ActiveRecord::Base.no_touching do
      # First, destroy step contents
      destroy_contents

      # Now, clone source's step contents
      Protocol.clone_contents(source, self, current_user, false)
    end

    # Lastly, update the metadata
    reload
    self.name = source.name
    self.record_timestamps = false
    self.updated_at = source.published_on
    self.parent = source
    self.parent_updated_at = source.published_on
    self.added_by = current_user
    self.protocol_type = Protocol.protocol_types[:linked]
    save!
  end

  def copy_to_repository(clone, current_user)
    clone.team = team
    clone.protocol_type = :in_repository_draft
    clone.added_by = current_user
    # Don't proceed further if clone is invalid
    return clone if clone.invalid?

    ActiveRecord::Base.no_touching do
      # Okay, clone seems to be valid: let's clone it
      clone = deep_clone(clone, current_user)
    end

    clone
  end

  def deep_clone_my_module(my_module, current_user)
    clone = Protocol.new_blank_for_module(my_module)
    clone.name = name
    clone.authors = authors
    clone.description = description
    clone.protocol_type = protocol_type

    if linked?
      clone.added_by = current_user
      clone.parent = parent
      clone.parent_updated_at = parent_updated_at
    end

    deep_clone(clone, current_user)
  end

  def deep_clone_repository(current_user)
    clone = Protocol.new(
      name: name,
      authors: authors,
      description: description,
      added_by: current_user,
      team: team,
      protocol_type: :in_repository_draft,
      skip_user_assignments: true
    )

    cloned = deep_clone(clone, current_user)

    if cloned
      deep_clone_user_assginments(clone)
      Activities::CreateActivityService
        .call(activity_type: :copy_protocol_in_repository,
              owner: current_user,
              subject: self,
              team: team,
              project: nil,
              message_items: {
                protocol_new: clone.id,
                protocol_original: id
              })
    end
    cloned
  end

  def destroy_contents
    # Calculate total space taken by the protocol
    st = space_taken
    steps.order(position: :desc).each do |step|
      step.step_orderable_elements.delete_all
      step.destroy!
    end

    # Release space taken by the step
    team.release_space(st)
    team.save

    # Reload protocol
    reload
  end

  def can_destroy?
    steps.map(&:can_destroy?).all?
  end

  def create_public_user_assignments!(assigned_by)
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

  def auto_assign_protocol_members
    UserAssignments::ProtocolGroupAssignmentJob.perform_now(
      team,
      self,
      last_modified_by || created_by
    )
  end

  def update_user_assignments
    case visibility
    when 'visible'
      create_public_user_assignments!(added_by)
    when 'hidden'
      automatic_user_assignments.where.not(user: added_by).destroy_all
    end
  end

  def deep_clone(clone, current_user)
    # Save cloned protocol first
    success = clone.save

    # Rename protocol if needed
    unless success
      rename_record(clone, :name)
      success = clone.save
    end

    raise ActiveRecord::RecordNotSaved unless success

    Protocol.clone_contents(self, clone, current_user, true, true)

    clone.reload
    clone
  end

  def update_linked_children
    # Increment/decrement the parent's nr of linked children
    if saved_change_to_parent_id?
      unless parent_id_before_last_save.nil?
        p = Protocol.find_by_id(parent_id_before_last_save)
        p.record_timestamps = false
        p.decrement!(:nr_of_linked_children)
      end
      unless parent_id.nil?
        parent.record_timestamps = false
        parent.increment!(:nr_of_linked_children)
      end
    end
  end

  def decrement_linked_children
    parent.decrement!(:nr_of_linked_children) if parent.present?
  end

  def assign_version_number
    return if previous_version.blank?

    self.version_number = previous_version.version_number + 1
  end

  def prevent_update
    errors.add(:base, I18n.t('activerecord.errors.models.protocol.unchangable'))
  end

  def linked_parent_type_constrain
    unless parent.in_repository_published?
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_parent_type'))
    end
  end

  def version_parent_type_constrain
    unless parent.in_repository_published_original?
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_parent_type'))
    end
  end

  def draft_parent_type_constrain
    unless parent.in_repository_published_original?
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_parent_type'))
    end
  end

  def versions_same_name_constrain
    if parent.present? && !parent.name.eql?(name)
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_version_name'))
    end
  end

  def version_number_constrain
    if previous_version.present? && version_number != previous_version.version_number + 1
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_version_number'))
    end
  end
end
