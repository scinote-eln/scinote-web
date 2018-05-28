class RepositoryColumn < ApplicationRecord
  belongs_to :repository, optional: true
  belongs_to :created_by,
             foreign_key: :created_by_id,
             class_name: 'User',
             optional: true
  has_many :repository_cells, dependent: :destroy
  has_many :repository_rows, through: :repository_cells
  has_many :repository_list_items, dependent: :destroy

  enum data_type: Extends::REPOSITORY_DATA_TYPES

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :repository, case_sensitive: true }
  validates :created_by, presence: true
  validates :repository, presence: true
  validates :data_type, presence: true

  after_create :update_repository_table_states_with_new_column
  around_destroy :update_repository_table_states_with_removed_column

  scope :list_type, -> { where(data_type: 'RepositoryListValue') }
  scope :asset_type, -> { where(data_type: 'RepositoryAssetValue') }

  def self.name_like(query)
    where('repository_columns.name ILIKE ?', "%#{query}%")
  end

  def update_repository_table_states_with_new_column
    service = RepositoryTableStateColumnUpdateService.new
    service.update_states_with_new_column(repository)
  end

  def update_repository_table_states_with_removed_column
    # Calculate old_column_index - this can only be done before
    # record is deleted when we still have its index
    old_column_index = (
      Constants::REPOSITORY_TABLE_DEFAULT_STATE[:length] +
      repository.repository_columns
                .order(id: :asc)
                .pluck(:id)
                .index(id)
    ).to_s

    # Perform the destroy itself
    yield

    # Update repository table states
    service = RepositoryTableStateColumnUpdateService.new
    service.update_states_with_removed_column(
      repository, old_column_index
    )
  end

  def importable?
    Extends::REPOSITORY_IMPORTABLE_TYPES.include?(data_type.to_sym)
  end
end
