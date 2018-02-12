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

  after_create :update_repository_table_state

  def update_repository_table_state
    RepositoryTableState.update_state(self, nil, created_by)
  end
end
