# frozen_string_literal: true

class RepositorySnapshot < RepositoryBase
  belongs_to :original_repository, foreign_key: :parent_id, class_name: 'Repository', inverse_of: :repository_snapshots
  belongs_to :my_module, optional: true

  validates :name, presence: true, length: { maximum: Constants::NAME_MAX_LENGTH }
end
