# frozen_string_literal: true

class RepositorySnapshot < RepositoryBase
  enum status: { provisioning: 0, ready: 1, failed: 2 }
  after_save :refresh_report_references, if: :saved_change_to_selected
  before_destroy :refresh_report_references_on_destroy, prepend: true

  belongs_to :original_repository,
             foreign_key: :parent_id,
             class_name: 'Repository',
             inverse_of: :repository_snapshots,
             optional: true
  belongs_to :my_module, optional: true, touch: true
  has_one :repository_stock_consumption_column,
          -> { where(data_type: 'RepositoryStockConsumptionValue') },
          class_name: 'RepositoryColumn',
          foreign_key: :repository_id,
          inverse_of: :repository_snapshot,
          dependent: :destroy

  validates :name, presence: true, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :status, presence: true
  validate :only_one_selected_for_my_module, if: ->(obj) { obj.changed.include? 'selected' }

  scope :of_unassigned_from_project, lambda { |project|
    joins(my_module: { experiment: :project })
      .where(my_modules: { experiments: { project: project } })
      .left_outer_joins(:original_repository)
      .where.not(original_repository: Repository.assigned_to_project(project))
      .select('DISTINCT ON ("repositories"."parent_id") "repositories".*')
      .order(:parent_id, updated_at: :desc)
  }

  scope :assigned_to_project, lambda { |project|
    where(team: project.team)
      .joins(my_module: { experiment: :project })
      .where(my_module: { experiments: { project: project } })
  }

  def self.create_preliminary!(repository, my_module, created_by = nil)
    created_by ||= repository.created_by
    create!(
      name: repository.name,
      original_repository: repository,
      team: my_module.experiment.project.team,
      status: :provisioning,
      my_module:,
      created_by:
    )
  end

  def default_table_state
    Constants::REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE
  end

  def assigned_rows(my_module)
    return RepositoryRow.none if my_module != self.my_module

    repository_rows
  end

  def default_search_fileds
    ['repository_rows.name', "('#{RepositoryRow::ID_PREFIX}' || repository_rows.parent_id)", 'users.full_name']
  end

  private

  def only_one_selected_for_my_module
    return unless selected

    if my_module.repository_snapshots.where(original_repository: original_repository, selected: true).any?
      errors.add(:selected, I18n.t('activerecord.errors.models.repository_snapshot.attributes.selected.already_taken'))
    end
  end

  def refresh_report_references
    if selected
      repositories = RepositoryBase.where(id: parent_id).or(RepositoryBase.where(parent_id: parent_id))
      my_module.report_elements.where(repository: repositories).update(repository: self)
    elsif original_repository
      my_module.update_report_repository_references(original_repository)
    end
  end

  def refresh_report_references_on_destroy
    return my_module.update_report_repository_references(original_repository) if original_repository

    repository_snapshot = my_module.repository_snapshots.where(parent_id: parent_id).order(created_at: :desc).first
    my_module.update_report_repository_references(repository_snapshot) if repository_snapshot
  end
end
