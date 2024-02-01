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
  validate :prevent_self_connections, :prevent_reciprocal_connections

  def parent?(repository_row)
    parent_id == repository_row.id
  end

  def child?(repository_row)
    child_id == repository_row.id
  end

  private

  def prevent_self_connections
    if parent_id == child_id
      errors.add(:base, I18n.t('activerecord.errors.models.repository_row_connection.self_connection'))
    end
  end

  def prevent_reciprocal_connections
    if parent_id && child_id && RepositoryRowConnection.exists?(parent_id: child_id, child_id: parent_id)
      errors.add(:base, I18n.t('activerecord.errors.models.repository_row_connection.reciprocal_connection'))
    end
  end

  def relationship_type(repository_row)
    return :parent if parent?(repository_row)

    return :child if child?(repository_row)

    nil
  end
end
