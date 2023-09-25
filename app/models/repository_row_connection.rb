# frozen_string_literal: true

class RepositoryRowConnection < ApplicationRecord
  belongs_to :parent,
             class_name: 'RepositoryRow',
             inverse_of: :child_connections,
             counter_cache: :child_connections_count
  belongs_to :child,
             class_name: 'RepositoryRow',
             inverse_of: :parent_connections,
             counter_cache: :parent_connections_count
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'

  validates :parent_id, uniqueness: { scope: :child_id }
end
