class RepositoryColumn < ActiveRecord::Base
  belongs_to :repository
  belongs_to :team
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  has_many :repository_cells, dependent: :destroy
  has_many :repository_rows, through: :repository_cells

  enum data_type: Extends::REPOSITORY_DATA_TYPES

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :team, case_sensitive: true }
  validates :team, :data_type, presence: true
  validates :created_by, presence: true
  validates :repository, presence: true
end
