class RepositoryTableState < ApplicationRecord
  belongs_to :user, inverse_of: :repository_table_states, optional: true
  belongs_to :repository, inverse_of: :repository_table_states, optional: true

  validates :user, :repository, presence: true
end
