# frozen_string_literal: true

class RepositorySnapshot < RepositoryBase
  enum status: { provisioning: 0, ready: 1, failed: 2 }

  belongs_to :original_repository, foreign_key: :parent_id, class_name: 'Repository', inverse_of: :repository_snapshots
  belongs_to :my_module, optional: true

  validates :name, presence: true, length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :status, presence: true

  def default_columns_count
    Constants::REPOSITORY_SNAPSHOT_TABLE_DEFAULT_STATE['length']
  end
end
