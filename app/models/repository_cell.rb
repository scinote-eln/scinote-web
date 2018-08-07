class RepositoryCell < ActiveRecord::Base
  attr_accessor :importing

  belongs_to :repository_row
  belongs_to :repository_column
  belongs_to :value, polymorphic: true,
                     inverse_of: :repository_cell,
                     dependent: :destroy
  belongs_to :repository_text_value,
             (lambda do
               joins(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryTextValue' })
             end),
             optional: true, foreign_key: :value_id
  belongs_to :repository_date_value,
             (lambda do
               joins(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryDateValue' })
             end),
             optional: true, foreign_key: :value_id
  belongs_to :repository_list_value,
             (lambda do
               joins(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryListValue' })
             end),
             optional: true, foreign_key: :value_id
  belongs_to :repository_asset_value,
             (lambda do
               joins(:repository_cell)
               .where(repository_cells: { value_type: 'RepositoryAssetValue' })
             end),
             optional: true, foreign_key: :value_id

  validates :repository_column, presence: true
  validate :repository_column_data_type
  validates :repository_row,
            uniqueness: { scope: :repository_column },
            unless: :importing

  private

  def repository_column_data_type
    if value_type != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
