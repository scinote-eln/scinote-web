# frozen_string_literal: true

class Protocol < ApplicationRecord
  ID_PREFIX = 'PT'

  include ArchivableModel
  include PrefixedIdModel
  SEARCHABLE_ATTRIBUTES = ['protocols.name', 'protocols.description',
                           'protocols.authors', 'protocol_keywords.name', PREFIXED_ID_SQL].freeze
  REPOSITORY_TYPES = %i(in_repository_published_original in_repository_draft in_repository_published_version).freeze

  include SearchableModel
  include RenamingUtil
  include SearchableByNameModel
  include Assignable
  include PermissionCheckableModel
  include TinyMceImages

  after_create :update_automatic_user_assignments, if: -> { visible? && in_repository? && parent.blank? }
  before_update :change_visibility, if: :default_public_user_role_id_changed?
  after_update :update_automatic_user_assignments,
               if: -> { saved_change_to_default_public_user_role_id? && in_repository? }
  skip_callback :create, :after, :create_users_assignments, if: -> { in_module? }

  enum visibility: { hidden: 0, visible: 1 }
  enum protocol_type: {
    unlinked: 0,
    linked: 1,
    in_repository_private: 2, # Deprecated
    in_repository_public: 3, # Deprecated
    in_repository_archived: 4, # Deprecated
    in_repository_published_original: 5,
    in_repository_draft: 6,
    in_repository_published_version: 7
  }

  auto_strip_attributes :name, :description, nullify: false, if: lambda {
                                                                   name_changed? || description_changed?
                                                                 }
  # Name is required when its actually specified (i.e. :in_repository? is true)
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :team, presence: true
  validates :protocol_type, presence: true
  validate :prevent_update,
           on: :update,
           if: lambda {
             # skip check if only public role of visibility changed
             (changes.keys | %w(default_public_user_role_id visibility)).length != 2 &&
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
  end
  with_options if: :in_repository? do
    validates :name, presence: true
    validates :added_by, presence: true
    validates :my_module, absence: true
    validate :version_number_constraint
  end
  with_options if: :in_repository_published_version? do
    validates :parent, presence: true
    validate :parent_type_constraint
    validate :versions_same_name_constraint
  end
  with_options if: :in_repository_draft? do
    # Only one draft can exist for each protocol
    validate :ensure_single_draft
    validate :versions_same_name_constraint
  end
  with_options if: -> { in_repository? && !parent && !archived_changed?(from: false) } do |protocol|
    # Active protocol must have unique name inside its team
    protocol
      .validates_uniqueness_of :name, case_sensitive: false,
                               scope: :team,
                               conditions: lambda {
                                 where(
                                   protocol_type: [
                                     Protocol.protocol_types[:in_repository_published_original],
                                     Protocol.protocol_types[:in_repository_draft]
                                   ],
                                   parent_id: nil
                                 )
                               }
  end
  with_options if: -> { in_repository? && archived? && !previous_version } do |protocol|
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
           -> { linked },
           class_name: 'Protocol',
           foreign_key: 'parent_id'
  has_one  :next_version,
           class_name: 'Protocol',
           foreign_key: 'previous_version_id',
           inverse_of: :previous_version,
           dependent: :destroy
  has_one  :latest_published_version,
           lambda {
             in_repository_published_version.select('DISTINCT ON (parent_id) *')
                                            .order(:parent_id, version_number: :desc)
           },
           class_name: 'Protocol',
           foreign_key: 'parent_id'
  has_one  :draft,
           -> { in_repository_draft.select('DISTINCT ON (parent_id) *').order(:parent_id) },
           class_name: 'Protocol',
           foreign_key: 'parent_id'
  has_many :published_versions,
           -> { in_repository_published_version },
           class_name: 'Protocol',
           foreign_key: 'parent_id',
           inverse_of: :parent,
           dependent: :destroy
  has_many :linked_my_modules,
           through: :linked_children,
           source: :my_module
  has_many :protocol_protocol_keywords,
           inverse_of: :protocol,
           dependent: :destroy
  has_many :protocol_keywords, through: :protocol_protocol_keywords
  has_many :steps, inverse_of: :protocol, dependent: :destroy
  has_many :users, through: :user_assignments

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    repository_protocols = latest_available_versions(user.teams)
                           .with_granted_permissions(user, ProtocolPermissions::READ)
                           .select(:id)
    repository_protocols = repository_protocols.active unless include_archived

    module_ids = MyModule.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT).pluck(:id)

    new_query = Protocol
                .where(
                  '(protocol_type IN (?) AND my_module_id IN (?)) OR (protocols.id IN (?))',
                  [Protocol.protocol_types[:unlinked], Protocol.protocol_types[:linked]],
                  module_ids,
                  repository_protocols
                )

    new_query = new_query.left_outer_joins(:protocol_keywords)
                         .where_attributes_like(SEARCHABLE_ATTRIBUTES, query, options)
                         .distinct

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def self.latest_available_versions(teams)
    team_protocols = where(team: teams)

    original_without_versions = team_protocols
                                .left_outer_joins(:published_versions)
                                .where(protocol_type: Protocol.protocol_types[:in_repository_published_original])
                                .where(published_versions: { id: nil })
                                .select(:id)
    published_versions = team_protocols
                         .where(protocol_type: Protocol.protocol_types[:in_repository_published_version])
                         .order(:parent_id, version_number: :desc)
                         .select('DISTINCT ON (parent_id) id')
    new_drafts = team_protocols
                 .where(protocol_type: Protocol.protocol_types[:in_repository_draft], parent_id: nil)
                 .select(:id)

    where('protocols.id IN ((?) UNION (?) UNION (?))', original_without_versions, published_versions, new_drafts)
  end

  def self.viewable_by_user(user, teams)
    # Team owners see all protocol templates in the team
    owner_role = UserRole.find_predefined_owner_role
    protocols = Protocol.where(team: teams)
                        .where(protocol_type: REPOSITORY_TYPES)
    viewable_as_team_owner = protocols.joins("INNER JOIN user_assignments team_user_assignments " \
                                             "ON team_user_assignments.assignable_type = 'Team' " \
                                             "AND team_user_assignments.assignable_id = protocols.team_id")
                                      .where(team_user_assignments: { user_id: user, user_role_id: owner_role })
                                      .select(:id)
    viewable_as_assigned = protocols.with_granted_permissions(user, ProtocolPermissions::READ).select(:id)

    where('protocols.id IN ((?) UNION (?))', viewable_as_team_owner, viewable_as_assigned)
  end

  def self.filter_by_teams(teams = [])
    teams.blank? ? self : where(team: teams)
  end

  def self.docx_parser_enabled?
    ENV.fetch('PROTOCOLS_PARSER_URL', nil).present?
  end

  def original_code
    # returns linked protocol code, or code of the original version of the linked protocol
    parent&.parent&.code || parent&.code || code
  end

  def insert_step(step, position)
    ActiveRecord::Base.transaction do
      steps.where('position >= ?', position).desc_order.each do |s|
        s.update!(position: s.position + 1)
      end
      step.position = position
      step.protocol = self
      step.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message
      raise ActiveRecord::Rollback
    end
    step
  end

  def created_by
    in_module? ? my_module.created_by : added_by
  end

  # Only for original published protocol
  def published_versions_with_original
    return Protocol.none unless in_repository_published_original?

    team.protocols
        .in_repository_published_version
        .where(parent: self)
        .or(team.protocols.in_repository_published_original.where(id: id))
  end

  # Only for original published protocol
  def all_linked_children
    return Protocol.none unless in_repository_published_original?

    Protocol.linked.where(parent: published_versions_with_original)
  end

  def initial_draft?
    in_repository_draft? && parent.blank?
  end

  def newer_published_version_present?
    if in_repository_published_original?
      published_versions.any?
    elsif in_repository_published_version?
      parent.published_versions.where('version_number > ?', version_number).any?
    else
      false
    end
  end

  def latest_published_version_or_self
    latest_published_version || self
  end

  def permission_parent
    in_module? ? my_module : team
  end

  def linked_modules
    MyModule.joins(:protocols).where(protocols: { parent_id: id })
  end

  def linked_experiments(linked_mod)
    Experiment.where(id: linked_mod.distinct.select(:experiment_id))
  end

  def linked_projects(linked_exp)
    Project.where(id: linked_exp.distinct.select(:project_id))
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

  def newer_than_parent?
    return linked? if linked_at.nil?

    linked? && updated_at > linked_at
  end

  def parent_newer?
    linked? && (
      parent.newer_published_version_present? ||
        # backward compatibility with original implementation
        parent.published_on > updated_at
    )
  end

  def number_of_steps
    steps.count
  end

  def archived_branch?
    archived? || parent&.archived?
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

  def archive(user)
    return false unless can_destroy?

    self.archived_by = user
    self.archived_on = Time.now
    self.restored_by = nil
    self.restored_on = nil
    self.archived = true
    result = save

    # Update all module protocols that had
    # parent set to this protocol
    if result
      reload
      Protocol.where(
        parent: self,
        protocol_type: %i(in_repository_draft in_repository_published_version)
      ).update(
        archived_by: user,
        archived_on: archived_on,
        restored_by: nil,
        restored_on: nil,
        archived: true
      )

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
      reload
      Protocol.where(
        parent: self,
        protocol_type: %i(in_repository_draft in_repository_published_version)
      ).update(
        archived_by: nil,
        archived_on: nil,
        restored_by: user,
        restored_on: restored_on,
        archived: false
      )

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

  def update_keywords(keywords, user)
    result = true
    begin
      Protocol.transaction do
        # First, destroy all keywords
        protocol_protocol_keywords.destroy_all
        if keywords.present?
          keywords.each do |kw_name|
            kw = ProtocolKeyword.find_or_create_by(name: kw_name, team: team)
            protocol_keywords << kw
          end
          update(last_modified_by: user)
        end
      end
    rescue StandardError
      result = false
    end
    result
  end

  def unlink
    self.parent = nil
    self.linked_at = nil
    self.protocol_type = Protocol.protocol_types[:unlinked]
    save!
  end

  def update_from_parent(current_user, source)
    ActiveRecord::Base.no_touching do
      # First, destroy step contents
      destroy_contents

      # Now, clone parent's step contents
      Protocol.clone_contents(source, self, current_user, false)
    end

    # Lastly, update the metadata
    reload
    self.record_timestamps = false
    self.added_by = current_user
    self.last_modified_by = current_user
    self.parent = source
    self.updated_at = Time.zone.now
    self.linked_at = updated_at
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
    self.parent = source
    self.added_by = current_user
    self.last_modified_by = current_user
    self.protocol_type = Protocol.protocol_types[:linked]
    self.updated_at = Time.zone.now
    self.linked_at = updated_at
    save!
  end

  def copy_to_repository(clone, current_user)
    clone.team = team
    clone.protocol_type = :in_repository_draft
    clone.added_by = current_user
    clone.last_modified_by = current_user
    clone.description = description
    # Don't proceed further if clone is invalid
    return clone if clone.invalid?

    ActiveRecord::Base.no_touching do
      # Okay, clone seems to be valid: let's clone it
      clone = deep_clone(clone, current_user)
    end

    clone
  end

  def save_as_draft(current_user)
    parent_protocol = parent || self
    version = (parent_protocol.latest_published_version || self).version_number + 1

    draft = dup
    draft.version_number = version
    draft.protocol_type = :in_repository_draft
    draft.parent = parent_protocol
    draft.published_by = nil
    draft.published_on = nil
    draft.version_comment = nil
    draft.previous_version = self
    draft.last_modified_by = current_user
    draft.skip_user_assignments = true

    return draft if draft.invalid?

    ActiveRecord::Base.no_touching do
      draft = deep_clone(draft, current_user)
    end

    parent_protocol.user_assignments.each do |parent_user_assignment|
      parent_protocol.sync_child_protocol_user_assignment(parent_user_assignment, draft.id)
    end

    draft
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
      clone.linked_at = linked_at
    end

    ActiveRecord::Base.no_touching do
      clone = deep_clone(clone, current_user)
    end
    clone
  end

  def deep_clone_repository(current_user)
    clone = Protocol.new(
      name: name,
      authors: authors,
      description: description,
      added_by: current_user,
      last_modified_by: current_user,
      team: team,
      protocol_type: :in_repository_draft
    )

    cloned = deep_clone(clone, current_user)

    if cloned
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

  def child_version_protocols
    published_versions.or(Protocol.where(id: draft&.id))
  end

  def sync_child_protocol_user_assignment(user_assignment, child_protocol_id = nil)
    # Copy user assignments to child protocol(s)

    Protocol.transaction(requires_new: true) do
      # Reload to ensure a potential new draft is also included in child versions
      reload

      (
        # all or single child version protocol
        child_protocol_id ? child_version_protocols.where(id: child_protocol_id) : child_version_protocols
      ).find_each do |child_protocol|
        child_assignment = child_protocol.user_assignments.find_or_initialize_by(
          user: user_assignment.user
        )

        if user_assignment.destroyed?
          child_assignment.destroy! if child_assignment.persisted?
          next
        end

        child_assignment.update!(
          user_assignment.attributes.slice(
            'user_role_id',
            'assigned',
            'assigned_by_id',
            'team_id'
          )
        )
      end
    end
  end

  private

  def after_user_assignment_changed(user_assignment)
    return unless in_repository_published_original?

    sync_child_protocol_user_assignment(user_assignment)
  end

  def update_automatic_user_assignments
    return if skip_user_assignments

    case visibility
    when 'visible'
      create_or_update_public_user_assignments!(added_by)
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

  def prevent_update
    errors.add(:base, I18n.t('activerecord.errors.models.protocol.unchangable'))
  end

  def linked_parent_type_constrain
    unless parent.in_repository_published?
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_parent_type'))
    end
  end

  def parent_type_constraint
    unless parent.in_repository_published_original?
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_parent_type'))
    end
  end

  def versions_same_name_constraint
    if parent.present? && !parent.name.eql?(name)
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_version_name'))
    end
  end

  def version_number_constraint
    if Protocol.where(protocol_type: Protocol::REPOSITORY_TYPES)
               .where.not(id: id)
               .where(version_number: version_number)
               .where('(parent_id = :parent_id OR id = :parent_id)', parent_id: (parent_id || id)).any?
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_version_number'))
    end
  end

  def ensure_single_draft
    if parent&.draft && parent.draft.id != id
      errors.add(:base, I18n.t('activerecord.errors.models.protocol.wrong_parent_draft_number'))
    end
  end

  def change_visibility
    self.visibility = default_public_user_role_id.present? ? :visible : :hidden
  end
end
