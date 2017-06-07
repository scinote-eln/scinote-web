class RepositoryRow < ActiveRecord::Base
  belongs_to :repository
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id,
                                class_name: 'User'
  has_many :repository_cells, dependent: :destroy
  has_many :repository_columns, through: :repository_cells
  has_many :my_module_repository_rows,
           inverse_of: :repository_row, dependent: :destroy
  has_many :my_modules, through: :my_module_repository_rows

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :created_by, presence: true
end
