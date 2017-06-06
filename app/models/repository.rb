class Repository < ActiveRecord::Base
  belongs_to :team
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  has_many :repository_columns
  has_many :repository_rows
  has_many :repository_tables, inverse_of: :repository, dependent: :destroy

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            uniqueness: { scope: :team, case_sensitive: false },
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :team, presence: true
  validates :created_by, presence: true
end
