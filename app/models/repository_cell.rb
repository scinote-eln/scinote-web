class RepositoryCell < ActiveRecord::Base
  belongs_to :repository_row
  belongs_to :repository_column
  belongs_to :value, polymorphic: true, dependent: :destroy

  validate :repository_column_data_type
  validates :repository_row, uniqueness: { scope: :repository_column }

  private

  def repository_column_data_type
    if value_type != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
