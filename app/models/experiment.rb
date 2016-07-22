class Experiment < ActiveRecord::Base
  include ArchivableModel

  belongs_to :project, inverse_of: :experiments
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :updated_by, foreign_key: :updated_by_id, class_name: 'User'
  belongs_to :archived_by, foreign_key: :archived_by_id, class_name: 'User'
  belongs_to :restored_by, foreign_key: :restored_by_id, class_name: 'User'

  has_many :my_modules, inverse_of: :experiment, dependent: :destroy
  has_many :my_module_groups, inverse_of: :experiment, dependent: :destroy

  validates :name,
            presence: true,
            length: { minimum: 4, maximum: 50 },
            uniqueness: { scope: :project, case_sensitive: false }
  validates :description, length: { maximum: 255 }
  validates :project, presence: true
  validates :created_by, presence: true
  validates :updated_by, presence: true
  with_options if: :archived do |experiment|
    experiment.validates :archived_by, presence: true
    experiment.validates :archived_on, presence: true
  end
end
