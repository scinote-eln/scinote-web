# frozen_string_literal: true

class Protocol < ApplicationRecord
  ID_PREFIX = 'PT'

  include ArchivableModel
  include PrefixedIdModel
  SEARCHABLE_ATTRIBUTES = ['protocols.name', 'protocols.description', PREFIXED_ID_SQL, :children].freeze
  REPOSITORY_TYPES = %i(in_repository_published_original in_repository_draft in_repository_published_version).freeze

  include SearchableModel
  include RenamingUtil
  include SearchableByNameModel
  include Assignable
  include PermissionCheckableModel
  include TinyMceImages
  include ObservableModel

  before_create -> { self.skip_user_assignments = true }, if: -> { in_module? }

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
  end
  with_options if: :in_repository_draft? do
    # Only one draft can exist for each protocol
    validate :ensure_single_draft
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
  has_many :original_steps, class_name: 'Step', foreign_key: :original_protocol_id, inverse_of: :original_protocol, dependent: :nullify

  def self.search(user,
                  include_archived,
                  query = nil,
                  current_team = nil,
                  options = {})
    team_ids = options[:teams]&.pluck(:id) || current_team&.id || user.teams.pluck(:id)

    if options[:options]&.dig(:in_repository)
      protocols = latest_available_versions(team_ids).readable_by_user(user, team_ids)
      protocols = protocols.active unless include_archived
    else
      protocols = joins(:my_module).where(my_modules: { id: MyModule.readable_by_user(user, team_ids) })
      unless include_archived
        protocols = protocols.active
                             .joins(my_module: { experiment: :project })
                             .where(my_modules: { archived: false }, experiments: { archived: false }, projects: { archived: false })
      end
    end

    protocols.where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query)
  end

  def self.where_children_attributes_like(query)
    from(
      "(#{unscoped.joins(:steps).where_attributes_like(Step::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION ALL
      #{unscoped.joins(steps: :step_texts).where_attributes_like(StepText::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION ALL
      #{unscoped.joins(steps: { step_tables: :table }).where_attributes_like(Table::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION ALL
      #{unscoped.joins(steps: :checklists).where_attributes_like(Checklist::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION ALL
      #{unscoped.joins(steps: { checklists: :checklist_items }).where_attributes_like(ChecklistItem::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION ALL
      #{unscoped.joins(steps: :step_comments).where_attributes_like(StepComment::SEARCHABLE_ATTRIBUTES, query).to_sql}
      ) AS protocols",
      :protocols
    )
  end

  def self.search_by_search_fields_with_boolean(user, teams = [], query = nil, search_fields = [], options = {})
    protocol_templates = latest_available_versions(teams).readable_by_user(user, teams)
    protocol_my_modules = joins(:my_module).where(my_modules: { id: MyModule.readable_by_user(user, teams) })

    where('protocols.id IN ((?) UNION (?))', protocol_templates.select(:id), protocol_my_modules.select(:id))
      .where_attributes_like_boolean(search_fields, query, options)
      .limit(options[:limit] || Constants::SEARCH_LIMIT)
  end

  def self.latest_available_versions(teams)
    team_protocols = where(team_id: teams)

    original_without_versions = team_protocols
                                .where.missing(:published_versions)
                                .where(protocol_type: Protocol.protocol_types[:in_repository_published_original])
                                .select(:id)
    published_versions = team_protocols
                         .where(protocol_type: Protocol.protocol_types[:in_repository_published_version])
                         .order(:parent_id, version_number: :desc)
                         .select('DISTINCT ON (parent_id) id')
    new_drafts = team_protocols
                 .where(protocol_type: Protocol.protocol_types[:in_repository_draft], parent_id: nil)
                 .select(:id)

    where('protocols.id IN ((?) UNION ALL (?) UNION ALL (?))', original_without_versions, published_versions, new_drafts)
  end

  def self.latest_available_versions_without_drafts(teams)
    team_protocols = where(team: teams)

    original_without_versions = team_protocols
                                .where.missing(:published_versions)
                                .where(protocol_type: Protocol.protocol_types[:in_repository_published_original])
                                .select(:id)
    published_versions = team_protocols
                         .where(protocol_type: Protocol.protocol_types[:in_repository_published_version])
                         .order(:parent_id, version_number: :desc)
                         .select('DISTINCT ON (parent_id) id')

    where('protocols.id IN ((?) UNION ALL (?))', original_without_versions, published_versions)
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
  # There is an issue with Delayed Job delayed methods, ruby 3, and keyword arguments (https://github.com/collectiveidea/delayed_job/issues/1134)
  # so we're forced to use a normal argument with default value.
  def self.deep_clone_assets(assets_to_clone, include_file_versions = false)
    ActiveRecord::Base.no_touching do
      assets_to_clone.each do |src_id, dest_id|
        src = Asset.find_by(id: src_id)
        dest = Asset.find_by(id: dest_id)
        dest.destroy! if src.blank? && dest.present?
        next unless src.present? && dest.present?

        # Clone file
        src.duplicate_file(dest, include_file_versions: include_file_versions)
      end
    end
  end

  def self.clone_contents(src, dest, current_user, clone_keywords, only_contents: false, include_file_versions: false)
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
      clone_step(dest, current_user, step, include_file_versions)
    end
  end

  def self.clone_step(protocol_dest, current_user, step, include_file_versions)
    step.duplicate(protocol_dest, current_user, step_position: step.position, include_file_versions: include_file_versions)
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
      draft = deep_clone(draft, current_user, include_file_versions: true)
    end

    parent_protocol.user_assignments.each do |parent_user_assignment|
      parent_protocol.sync_child_protocol_assignment(parent_user_assignment, draft.id)
    end

    parent_protocol.user_group_assignments.each do |parent_user_group_assignment|
      parent_protocol.sync_child_protocol_assignment(parent_user_group_assignment, draft.id)
    end

    parent_protocol.team_assignments.each do |parent_team_assignment|
      parent_protocol.sync_child_protocol_assignment(parent_team_assignment, draft.id)
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
    steps.order(position: :desc).destroy_all

    # Release space taken by the step
    team.release_space(st)
    team.save

    # Reload protocol
    reload
  end

  def can_destroy?
    steps.map(&:can_destroy?).all?
  end

  def child_version_protocols
    published_versions.or(Protocol.where(id: draft&.id))
  end

  def sync_child_protocol_assignment(assignment, child_protocol_id = nil)
    # Copy user assignments to child protocol(s)

    Protocol.transaction(requires_new: true) do
      # Reload to ensure a potential new draft is also included in child versions
      reload
      assignment_key = assignment.model_name.param_key
      assignable_id_key = assignment_key.gsub('assignment', 'id')

      (
        # all or single child version protocol
        child_protocol_id ? child_version_protocols.where(id: child_protocol_id) : child_version_protocols
      ).find_each do |child_protocol|
        child_assignment = child_protocol.public_send(assignment_key.pluralize).find_or_initialize_by(
          assignable_id_key => assignment.public_send(assignable_id_key)
        )

        if assignment.destroyed?
          child_assignment.destroy! if child_assignment.persisted?
          next
        end

        child_assignment.update!(
          assignment.attributes.slice(
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
    return if skip_user_assignments || !in_repository_published_original?

    sync_child_protocol_assignment(user_assignment)
  end

  def after_user_group_assignment_changed(user_group_assignment)
    return if skip_user_assignments || !in_repository_published_original?

    sync_child_protocol_assignment(user_group_assignment)
  end

  def after_team_assignment_changed(user_group_assignment)
    return if skip_user_assignments || !in_repository_published_original?

    sync_child_protocol_assignment(user_group_assignment)
  end

  def deep_clone(clone, current_user, include_file_versions: false)
    # Save cloned protocol first
    success = clone.save

    # Rename protocol if needed
    unless success
      rename_record(clone, :name)
      success = clone.save
    end

    raise ActiveRecord::RecordNotSaved unless success

    Protocol.clone_contents(self, clone, current_user, true, only_contents: true, include_file_versions: include_file_versions)

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
end
