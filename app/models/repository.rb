# frozen_string_literal: true

class Repository < RepositoryBase
  include SearchableModel
  include SearchableByNameModel
  include Assignable
  include PermissionCheckableModel
  include RepositoryImportParser
  include ArchivableModel
  include Shareable

  ID_PREFIX = 'IN'
  include PrefixedIdModel

  belongs_to :archived_by,
             foreign_key: :archived_by_id,
             class_name: 'User',
             inverse_of: :archived_repositories,
             optional: true
  belongs_to :restored_by,
             foreign_key: :restored_by_id,
             class_name: 'User',
             inverse_of: :restored_repositories,
             optional: true
  belongs_to :repository_template, inverse_of: :repositories, optional: true
  has_many :repository_snapshots,
           class_name: 'RepositorySnapshot',
           foreign_key: :parent_id,
           inverse_of: :original_repository
  has_many :repository_ledger_records, as: :reference, dependent: :nullify
  has_many :repository_table_filters, dependent: :destroy

  before_save :sync_name_with_snapshots, if: :name_changed?
  before_destroy :refresh_report_references_on_destroy, prepend: true
  after_save :assign_globally_shared_inventories, if: -> { saved_change_to_permission_level? && globally_shared? }
  after_save :unassign_globally_shared_inventories, if: -> { saved_change_to_permission_level? && !globally_shared? }
  after_save :unassign_unshared_items, if: :saved_change_to_permission_level
  after_save :unlink_unshared_items, if: -> { saved_change_to_permission_level? && !globally_shared? }

  validates :name,
            presence: true,
            uniqueness: { scope: :team_id, case_sensitive: false },
            length: { maximum: Constants::NAME_MAX_LENGTH }

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }
  scope :globally_shared, -> { where(permission_level: %i(shared_read shared_write)) }

  scope :assigned_to_project, lambda { |project|
    joins(repository_rows: { my_module_repository_rows: { my_module: { experiment: :project } } })
      .where(repository_rows: { my_module_repository_rows: { my_module: { experiments: { project: project } } } })
  }

  scope :appendable_by_user, lambda { |user, teams = user.current_team|
    readable_ids = with_granted_permissions(user, RepositoryPermissions::ROWS_CREATE).where(team: teams).pluck(:id)
    shared_with_team_ids = joins(:team_shared_objects, :team).where(team_shared_objects: { team: teams, permission_level: :shared_write }).pluck(:id)
    globally_shared_ids =
      if column_names.include?('permission_level')
        joins(:team).where(
          {
            permission_level: [
              Extends::SHARED_OBJECTS_PERMISSION_LEVELS[:shared_write]
            ]
          }
        ).pluck(:id)
      else
        none.pluck(:id)
      end

    active.where(id: (readable_ids + shared_with_team_ids + globally_shared_ids).uniq)
  }

  def readable_by_user?(user)
    permission_granted?(user, RepositoryPermissions::READ)
  end

  def self.within_global_limits?
    return true unless Rails.configuration.x.global_repositories_limit.positive?

    count < Rails.configuration.x.global_repositories_limit
  end

  def self.within_team_limits?(team)
    return true unless Rails.configuration.x.team_repositories_limit.positive?

    team.repositories.count < Rails.configuration.x.team_repositories_limit
  end

  def self.filter_by_teams(teams = [])
    teams.blank? ? self : where(team: teams)
  end

  def permission_parent
    team
  end

  def default_table_state
    Constants::REPOSITORY_TABLE_DEFAULT_STATE
  end

  def default_sortable_columns
    [
      'assigned',
      'repository_rows.id',
      'repository_rows.name',
      'relationships',
      'repository_rows.created_at',
      'users.full_name',
      'repository_rows.updated_at',
      'last_modified_by.full_name',
      'repository_rows.archived_on',
      'archived_by.full_name'
    ]
  end

  def default_search_fileds
    ['repository_rows.name', RepositoryRow::PREFIXED_ID_SQL, 'users.full_name']
  end

  def self.name_like(query)
    where('repositories.name ILIKE ?', "%#{query}%")
  end

  def importable_repository_fields
    fields = {}
    # First and foremost add record name
    fields['0'] = I18n.t('repositories.id_column')
    fields['-1'] = I18n.t('repositories.default_column')
    # Add all other custom columns
    repository_columns.order(:created_at).each do |rc|
      next unless rc.importable?

      fields[rc.id] = rc.name
    end
    fields
  end

  def copy(created_by, new_name)
    new_repo = nil

    begin
      Repository.transaction do
        # Clone the repository object
        new_repo = Repository.create!(name: new_name, team:, created_by:)

        # Clone columns (only if new_repo was saved)
        repository_columns.find_each do |col|
          new_col = col.dup
          new_col.repository = new_repo
          new_col.created_by = created_by
          new_col.save!
        end
      end
    rescue ActiveRecord::RecordInvalid
      return false
    end

    # If everything is okay, return new_repo
    Activities::CreateActivityService
      .call(activity_type: :copy_inventory,
            owner: created_by,
            subject: new_repo,
            team: new_repo.team,
            message_items: { repository_new: new_repo.id, repository_original: id })

    new_repo
  end

  def assigned_rows(my_module)
    repository_rows.joins(:my_module_repository_rows).where(my_module_repository_rows: { my_module_id: my_module.id })
  end

  def unassign_unshared_items
    return if shared_read? || shared_write?

    MyModuleRepositoryRow.joins(my_module: { experiment: { project: :team } })
                         .joins(repository_row: :repository)
                         .where(repository_rows: { repository: self })
                         .where.not(my_module: { experiment: { projects: { team: team } } })
                         .where.not(my_module: { experiment: { projects: { team: teams_shared_with } } })
                         .destroy_all
  end

  def unlink_unshared_items
    repository_rows_ids = repository_rows.select(:id)
    rows_to_unlink = RepositoryRow.joins("LEFT JOIN repository_row_connections \
                                         ON repository_rows.id = repository_row_connections.parent_id \
                                         OR repository_rows.id = repository_row_connections.child_id")
                                  .where("repository_row_connections.parent_id IN (?) \
                                         OR repository_row_connections.child_id IN (?)",
                                         repository_rows_ids,
                                         repository_rows_ids)
                                  .joins(:repository)
                                  .where.not(repository: self)
                                  .where.not(repositories: { team: team })
                                  .distinct

    RepositoryRowConnection.where(parent: repository_rows_ids, child: rows_to_unlink)
                           .destroy_all
    RepositoryRowConnection.where(child: repository_rows_ids, parent: rows_to_unlink)
                           .destroy_all
  end

  def archived_branch?
    archived?
  end

  private

  def sync_name_with_snapshots
    repository_snapshots.update(name: name)
  end

  def assign_globally_shared_inventories
    viewer_role = UserRole.find_by(name: UserRole.public_send('viewer_role').name)
    normal_user_role = UserRole.find_by(name: UserRole.public_send('normal_user_role').name)

    team_shared_objects.find_each(&:destroy!)

    Team.where.not(id: team.id).find_each do |team|
      team.users.find_each do |user|
        team.repository_sharing_user_assignments.find_or_initialize_by(
          user: user,
          assignable: self
        ).update!(user_role: shared_write? ? normal_user_role : viewer_role)
      end
    end
  end

  def unassign_globally_shared_inventories
    user_assignments.where.not(team: team).find_each(&:destroy!)
  end

  def refresh_report_references_on_destroy
    report_elements.find_each do |report_element|
      repository_snapshot = report_element.my_module
                                          .repository_snapshots
                                          .where(original_repository: self)
                                          .order(:selected, created_at: :desc)
                                          .first
      report_element.update(repository: repository_snapshot) if repository_snapshot
    end
  end
end
