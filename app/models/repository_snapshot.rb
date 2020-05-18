# frozen_string_literal: true

class RepositorySnapshot < RepositoryBase
  enum status: { provisioning: 0, ready: 1, failed: 2 }

  belongs_to :original_repository, foreign_key: :parent_id,
                                   class_name: 'Repository',
                                   inverse_of: :repository_snapshots,
                                   optional: true
  belongs_to :my_module, optional: true

  validates :name, presence: true, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :status, presence: true
  validate :only_one_selected_for_my_module, if: ->(obj) { obj.changed.include? :selected }

  scope :selected, -> { where(selected: true) }

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
end
