# frozen_string_literal: true

class RepositorySnapshot < RepositoryBase
  enum status: { provisioning: 0, ready: 1, failed: 2 }
  after_save :refresh_report_references, if: :saved_change_to_selected
  before_destroy :refresh_report_references_on_destroy, prepend: true

  belongs_to :original_repository, foreign_key: :parent_id,
                                   class_name: 'Repository',
                                   inverse_of: :repository_snapshots,
                                   optional: true
  belongs_to :my_module, optional: true

  validates :name, presence: true, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :status, presence: true
  validate :only_one_selected_for_my_module, if: ->(obj) { obj.changed.include? :selected }

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
