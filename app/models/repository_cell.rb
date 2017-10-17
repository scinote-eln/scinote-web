class RepositoryCell < ActiveRecord::Base
  attr_accessor :skip_on_import

  belongs_to :repository_row
  belongs_to :repository_column
  belongs_to :value, polymorphic: true, dependent: :destroy

  validates :repository_column, presence: true
  validate :repository_column_data_type
  validates :repository_row,
            uniqueness: { scope: :repository_column },
            unless: :skip_on_import

  private

  def repository_column_data_type
    if value_type != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
