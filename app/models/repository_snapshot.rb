# frozen_string_literal: true

class RepositorySnapshot < RepositoryBase
  enum status: { provisioning: 0, ready: 1, failed: 2 }
  after_save :refresh_report_references, if: :saved_change_to_selected
  before_destroy :refresh_report_references_for_destroy, prepend: true

  belongs_to :original_repository, -> { unscope(where: :archived) },
             foreign_key: :parent_id,
             class_name: 'Repository',
             inverse_of: :repository_snapshots,
             optional: true

  belongs_to :my_module, optional: true

  validates :name, presence: true, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :status, presence: true
  validate :only_one_selected_for_my_module, if: ->(obj) { obj.changed.include? :selected }

  scope :with_deleted_parent_by_team, lambda { |team|
    joins(my_module: { experiment: :project })
      .where('projects.team_id = ?', team.id)
      .left_outer_joins(:original_repository)
      .where(original_repositories_repositories: { id: nil })
      .select('DISTINCT ON ("repositories"."parent_id") "repositories".*')
      .order(:parent_id, updated_at: :desc)
  }

  def default_columns_count
    Constants::REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE['length']
  end

  def assigned_rows(_my_module)
    repository_rows
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
      ids = Repository.where(id: parent_id).pluck(:id) +
            RepositorySnapshot.where(parent_id: parent_id).pluck(:id)

      ReportElement.where(my_module: my_module).where(repository_id: ids).update(repository_id: id)
    elsif original_repository && !my_module.selected_snapshot_for_repo(original_repository.id)
      my_module.update_report_repository_references(original_repository)
    end
  end

  def refresh_report_references_for_destroy
    repository_or_snap = original_repository || self
    default_view_candidate =
      my_module.active_snapshot_or_live(repository_or_snap, exclude_snpashot_ids: [id])
    my_module.update_report_repository_references(default_view_candidate) if default_view_candidate
  end
end
