class RepositoryCell < ActiveRecord::Base
  belongs_to :repository_row
  belongs_to :repository_column
  belongs_to :value, polymorphic: true, dependent: :destroy

  validates :repository_column, presence: true
  validate :repository_column_data_type
  validates :repository_row,
            uniqueness: { scope: :repository_column }

  belongs_to :repository_text_value, optional: true, foreign_key: :value_id
  belongs_to :repository_date_value, optional: true, foreign_key: :value_id
  belongs_to :repository_list_value, optional: true, foreign_key: :value_id

  private

  def repository_column_data_type
    if value_type != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
