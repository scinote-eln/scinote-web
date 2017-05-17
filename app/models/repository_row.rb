class RepositoryRow < ActiveRecord::Base
  belongs_to :repository
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  has_many :repository_cells, dependent: :destroy
  has_many :repository_columns, through: :repository_cells

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :created_by, presence: true
end
