class RepositoryCell < ApplicationRecord
  belongs_to :repository_row, optional: true
  belongs_to :repository_column, optional: true
  belongs_to :value, polymorphic: true, dependent: :destroy, optional: true

  validates :repository_column, presence: true
  validate :repository_column_data_type
  validates :repository_row, uniqueness: { scope: :repository_column }

  private

  def repository_column_data_type
    if value_type != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
