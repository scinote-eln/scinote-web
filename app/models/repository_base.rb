# frozen_string_literal: true

class RepositoryBase < ApplicationRecord
  include Discard::Model

  self.table_name = 'repositories'

  attribute :discarded_by_id, :integer

  belongs_to :team
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :archived_by, foreign_key: :archived_by_id, class_name: 'User', inverse_of: :repository, optional: true
  has_many :repository_columns, foreign_key: :repository_id, inverse_of: :repository, dependent: :destroy
  has_many :repository_rows, foreign_key: :repository_id, inverse_of: :repository, dependent: :destroy
  has_many :repository_table_states, foreign_key: :repository_id, inverse_of: :repository, dependent: :destroy
  has_many :report_elements, inverse_of: :repository, dependent: :destroy, foreign_key: :repository_id

  auto_strip_attributes :name, nullify: false
  validates :team, presence: true
  validates :created_by, presence: true
  with_options if: :archived do
    validates :archived_by, presence: true
    validates :archived_on, presence: true
  end

  # Not discarded
  default_scope -> { kept }

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def cell_preload_includes
    cell_includes = []
    repository_columns.pluck(:data_type).each do |data_type|
      cell_includes << data_type.constantize::PRELOAD_INCLUDE
    end
    cell_includes
  end

  def destroy_discarded(discarded_by_id = nil)
    self.discarded_by_id = discarded_by_id
    destroy
  end
  handle_asynchronously :destroy_discarded, queue: :clear_discarded_repository, priority: 20
end
