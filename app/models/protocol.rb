class Protocol < ApplicationRecord
  include SearchableModel
  include RenamingUtil
  extend TinyMceHelper

  after_save :update_linked_children
  after_destroy :decrement_linked_children

  enum protocol_type: {
    unlinked: 0,
    linked: 1,
    in_repository_private: 2,
    in_repository_public: 3,
    in_repository_archived: 4
  }

  auto_strip_attributes :name, :description, nullify: false
  # Name is required when its actually specified (i.e. :in_repository? is true)
  validates :name, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :team, presence: true
  validates :protocol_type, presence: true

  with_options if: :in_module? do |protocol|
    protocol.validates :my_module, presence: true
    protocol.validates :published_on, absence: true
    protocol.validates :archived_by, absence: true
    protocol.validates :archived_on, absence: true
  end
  with_options if: :linked? do |protocol|
    protocol.validates :added_by, presence: true
    protocol.validates :parent, presence: true
    protocol.validates :parent_updated_at, presence: true
  end

  with_options if: :in_repository? do |protocol|
    protocol.validates :name, presence: true
    protocol.validates :added_by, presence: true
    protocol.validates :my_module, absence: true
    protocol.validates :parent, absence: true
    protocol.validates :parent_updated_at, absence: true
  end
  with_options if: :in_repository_public? do |protocol|
    # Public protocol must have unique name inside its team
    protocol
      .validates_uniqueness_of :name, case_sensitive: false,
                               scope: :team,
                               conditions: -> {
                                 where(
                                   protocol_type:
                                     Protocol
                                      .protocol_types[:in_repository_public]
                                 )
                               }
    protocol.validates :published_on, presence: true
  end
  with_options if: :in_repository_private? do |protocol|
    # Private protocol must have unique name inside its team & user scope
    protocol
      .validates_uniqueness_of :name, case_sensitive: false,
                               scope: [:team, :added_by],
                               conditions: -> {
                                 where(
                                   protocol_type:
                                     Protocol
                                       .protocol_types[:in_repository_private]
                                 )
                               }
  end
  with_options if: :in_repository_archived? do |protocol|
    # Archived protocol must have unique name inside its team & user scope
    protocol
      .validates_uniqueness_of :name, case_sensitive: false,
                               scope: [:team, :added_by],
                               conditions: -> {
                                 where(
                                   protocol_type:
                                    Protocol
                                      .protocol_types[:in_repository_archived]
                                 )
                               }
    protocol.validates :archived_by, presence: true
    protocol.validates :archived_on, presence: true
  end

  belongs_to :added_by,
             foreign_key: 'added_by_id',
             class_name: 'User',
             inverse_of: :added_protocols,
             optional: true
  belongs_to :my_module,
             inverse_of: :protocols,
             optional: true
  belongs_to :team, inverse_of: :protocols, optional: true
  belongs_to :parent,
             foreign_key: 'parent_id',
             class_name: 'Protocol',
             optional: true
  belongs_to :archived_by,
             foreign_key: 'archived_by_id',
             class_name: 'User',
             inverse_of: :archived_protocols, optional: true
  belongs_to :restored_by,
             foreign_key: 'restored_by_id',
             class_name: 'User',
             inverse_of: :restored_protocols, optional: true
  has_many :linked_children,
           class_name: 'Protocol',
           foreign_key: 'parent_id'
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
                   .where('user_teams.user_id = ?', user.id)
                   .distinct
                   .pluck(:id)

    module_ids = MyModule.search(user,
                                 include_archived,
                                 nil,
                                 Constants::SEARCH_NO_LIMIT)
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
                .where_attributes_like(
                  [
                    'protocols.name',
                    'protocols.description',
                    'protocols.authors',
                    'protocol_keywords.name'
                  ],
                  query, options
                )

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
    end
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
  def self.deep_clone_assets(assets_to_clone, team)
    assets_to_clone.each do |src_id, dest_id|
      src = Asset.find_by_id(src_id)
      dest = Asset.find_by_id(dest_id)
      dest.destroy! if src.blank? && dest.present?
      next unless src.present? && dest.present?
      # Clone file
      dest.file = src.file
      dest.save!

      if dest.is_image?
        dest.file.reprocess!(:large)
        dest.file.reprocess!(:medium)
      end

      # Clone extracted text data if it exists
      if (atd = src.asset_text_datum).present?
        atd2 = AssetTextDatum.new(
          data: atd.data,
          asset: dest
        )
        atd2.save!
      end

      # Update estimated size of cloned asset
      # (& file_present flag)
      dest.update(
        estimated_size: src.estimated_size,
        file_present: true
      )

      # Update team's space taken
      team.reload
      team.take_space(dest.estimated_size)
      team.save!
    end
  end

  def self.clone_contents(src, dest, current_user, clone_keywords)
    assets_to_clone = []

    # Update keywords
    if clone_keywords then
      src.protocol_keywords.each do |keyword|
        ProtocolProtocolKeyword.create(
          protocol: dest,
          protocol_keyword: keyword
        )
      end
    end

    # Copy steps
    src.steps.each do |step|
      step2 = Step.new(
        name: step.name,
        description: step.description,
        position: step.position,
        completed: false,
        user: current_user,
        protocol: dest
      )
      step2.save!

      # Copy checklists
      step.checklists.asc.each do |checklist|
        checklist2 = Checklist.new(
          name: checklist.name,
          step: step2
        )
        checklist2.created_by = current_user
        checklist2.last_modified_by = current_user
        checklist2.save!

        checklist.checklist_items.each do |item|
          item2 = ChecklistItem.new(
            text: item.text,
            checked: false,
            checklist: checklist2,
            position: item.position
          )
          item2.created_by = current_user
          item2.last_modified_by = current_user
          item2.save!
        end

        step2.checklists << checklist2
      end

      # "Shallow" Copy assets
      step.assets.each do |asset|
        asset2 = Asset.new_empty(
          asset.file_file_name,
          asset.file_file_size
        )
        asset2.created_by = current_user
        asset2.team = dest.team
        asset2.last_modified_by = current_user
        asset2.file_processing = true if asset.is_image?
        asset2.save!

        step2.assets << asset2
        assets_to_clone << [asset.id, asset2.id]
      end

      # Copy tables
      step.tables.each do |table|
        table2 = Table.new(
          name: table.name,
          contents: table.contents.encode('UTF-8', 'UTF-8')
        )
        table2.created_by = current_user
        table2.last_modified_by = current_user
        table2.team = dest.team
        step2.tables << table2
      end

      # Copy tinyMce assets
      cloned_img_ids = []
      step.tiny_mce_assets.each do |tiny_img|
        tiny_img2 = TinyMceAsset.new(
          image: tiny_img.image,
          estimated_size: tiny_img.estimated_size,
          step: step2,
          team: dest.team
        )
        tiny_img2.save

        step2.tiny_mce_assets << tiny_img2
        cloned_img_ids << [tiny_img.id, tiny_img2.id]
      end
      step2.update(
        description: replace_tiny_mce_assets(step2.description, cloned_img_ids)
      )
    end

    # Call clone helper
    Protocol.delay(queue: :assets).deep_clone_assets(
      assets_to_clone,
      dest.team
    )
  end

  def in_repository_active?
    in_repository_private? || in_repository_public?
  end

  def in_repository?
    in_repository_active? || in_repository_archived?
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

  def space_taken
    st = 0
    self.steps.find_each do |step|
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
    save
  end

  # This publish action simply moves the protocol from
  # the private section in the repository into the public
  # section
  def publish(user)
    # Don't update "updated_at" timestamp
    self.record_timestamps = false

    self.added_by = user
    self.published_on = Time.now
    self.archived_by = nil
    self.archived_on = nil
    self.restored_by = nil
    self.restored_on = nil
    self.protocol_type = Protocol.protocol_types[:in_repository_public]
    save
  end

  def archive(user)
    return nil unless can_destroy?

    # Don't update "updated_at" timestamp
    self.record_timestamps = false

    # We keep published_on present, so we know (upon restoring)
    # where the protocol was located

    self.archived_by = user
    self.archived_on = Time.now
    self.restored_by = nil
    self.restored_on = nil
    self.protocol_type = Protocol.protocol_types[:in_repository_archived]
    result = save

    # Update all module protocols that had
    # parent set to this protocol
    if result then
      Protocol.where(parent: self).find_each do |p|
        p.update(
          parent: nil,
          parent_updated_at: nil,
          protocol_type: :unlinked
        )
      end
    end

    result
  end

  def restore(user)
    # Don't update "updated_at" timestamp
    self.record_timestamps = false

    self.archived_by = nil
    self.archived_on = nil
    self.restored_by = user
    self.restored_on = Time.now
    if self.published_on.present?
      self.published_on = Time.now
      self.protocol_type = Protocol.protocol_types[:in_repository_public]
    else
      self.protocol_type = Protocol.protocol_types[:in_repository_private]
    end
    save
  end

  def update_keywords(keywords)
    result = true
    begin
      Protocol.transaction do
        self.record_timestamps = false

        # First, destroy all keywords
        self.protocol_protocol_keywords.destroy_all
        if keywords.present?
          keywords.each do |kw_name|
            kw = ProtocolKeyword.find_or_create_by(name: kw_name, team: team)
            self.protocol_keywords << kw
          end
        end
      end
    rescue
      result = false
    end
    result
  end

  def unlink
    self.parent = nil
    self.parent_updated_at = nil
    self.protocol_type = Protocol.protocol_types[:unlinked]
    self.save!
  end

  def update_parent(current_user)
    # First, destroy parent's step contents
    parent.destroy_contents(current_user)
    parent.reload

    # Now, clone step contents
    Protocol.clone_contents(self, self.parent, current_user, false)

    # Lastly, update the metadata
    parent.reload
    parent.record_timestamps = false
    parent.updated_at = self.updated_at
    parent.save!
    self.record_timestamps = false
    self.parent_updated_at = self.updated_at
    self.save!
  end

  def update_from_parent(current_user)
    # First, destroy step contents
    destroy_contents(current_user)

    # Now, clone parent's step contents
    Protocol.clone_contents(self.parent, self, current_user, false)

    # Lastly, update the metadata
    self.reload
    self.record_timestamps = false
    self.updated_at = self.parent.updated_at
    self.parent_updated_at = self.parent.updated_at
    self.added_by = current_user
    self.save!
  end

  def load_from_repository(source, current_user)
    # First, destroy step contents
    destroy_contents(current_user)

    # Now, clone source's step contents
    Protocol.clone_contents(source, self, current_user, false)

    # Lastly, update the metadata
    self.reload
    self.record_timestamps = false
    self.updated_at = source.updated_at
    self.parent = source
    self.parent_updated_at = source.updated_at
    self.added_by = current_user
    self.protocol_type = Protocol.protocol_types[:linked]
    self.save!
  end

  def copy_to_repository(new_name, new_protocol_type, link_protocols, current_user)
    clone = Protocol.new(
      name: new_name,
      protocol_type: new_protocol_type,
      added_by: current_user,
      team: self.team
    )
    if clone.in_repository_public?
      clone.published_on = Time.now
    end

    # Don't proceed further if clone is invalid
    if clone.invalid?
      return clone
    end

    # Okay, clone seems to be valid: let's clone it
    clone = deep_clone(clone, current_user)

    # If the above operation went well, update published_on
    # timestamp
    if clone.in_repository_public?
      clone.update(published_on: Time.now)
    end

    # Link protocols if neccesary
    if link_protocols then
      self.reload
      self.record_timestamps = false
      self.added_by = current_user
      self.parent = clone
      ts = clone.updated_at
      self.parent_updated_at = ts
      self.updated_at = ts
      self.protocol_type = Protocol.protocol_types[:linked]
      self.save!
    end

    return clone
  end

  def deep_clone_my_module(my_module, current_user)
    clone = Protocol.new_blank_for_module(my_module)
    clone.name = self.name
    clone.authors = self.authors
    clone.description = self.description
    clone.protocol_type = self.protocol_type

    if self.linked?
      clone.added_by = current_user
      clone.parent = self.parent
      clone.parent_updated_at = self.parent_updated_at
    end

    deep_clone(clone, current_user)
  end

  def deep_clone_repository(current_user)
    clone = Protocol.new(
      name: self.name,
      authors: self.authors,
      description: self.description,
      added_by: current_user,
      team: self.team,
      protocol_type: self.protocol_type,
      published_on: self.in_repository_public? ? Time.now : nil,
    )

    deep_clone(clone, current_user)
  end

  def destroy_contents(current_user)
    # Calculate total space taken by the protocol
    st = self.space_taken

    self.steps.find_each do |step|
      unless step.destroy(current_user) then
        raise ActiveRecord::RecordNotDestroyed
      end
    end

    # Release space taken by the step
    self.team.release_space(st)
    self.team.save

    # Reload protocol
    self.reload
  end

  def can_destroy?
    steps.map(&:can_destroy?).all?
  end

  private

  def deep_clone(clone, current_user)
    # Save cloned protocol first
    success = clone.save

    # Rename protocol if needed
    unless success
      rename_record(clone, :name)
      success = clone.save
    end

    raise ActiveRecord::RecordNotSaved unless success

    Protocol.clone_contents(self, clone, current_user, true)

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
      if self.parent_id != nil
        self.parent.record_timestamps = false
        self.parent.increment!(:nr_of_linked_children)
      end
    end
  end

  def decrement_linked_children
    self.parent.decrement!(:nr_of_linked_children) if self.parent.present?
  end

end
