# frozen_string_literal: true

class RepositoryColumn < ApplicationRecord
  belongs_to :repository
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  has_many :repository_cells, dependent: :destroy
  has_many :repository_rows, through: :repository_cells
  has_many :repository_list_items, -> { order('data ASC') }, dependent: :destroy,
                                                             index_errors: true,
                                                             inverse_of: :repository_column
  has_many :repository_status_items, -> { order('status ASC') }, dependent: :destroy,
                                                                 index_errors: true,
                                                                 inverse_of: :repository_column
  has_many :repository_checklist_items, -> { order('data ASC') }, dependent: :destroy,
                                                                  index_errors: true,
                                                                  inverse_of: :repository_column

  accepts_nested_attributes_for :repository_status_items, allow_destroy: true
  accepts_nested_attributes_for :repository_list_items, allow_destroy: true
  accepts_nested_attributes_for :repository_checklist_items, allow_destroy: true

  enum data_type: Extends::REPOSITORY_DATA_TYPES

  auto_strip_attributes :name, nullify: false
  validates :name,
            length: { maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: :repository_id, case_sensitive: true }
  validates :name, :data_type, :repository, :created_by, presence: true

  after_create :update_repository_table_states_with_new_column
  around_destroy :update_repository_table_states_with_removed_column

  scope :list_type, -> { where(data_type: 'RepositoryListValue') }
  scope :asset_type, -> { where(data_type: 'RepositoryAssetValue') }
  scope :status_type, -> { where(data_type: 'RepositoryStatusValue') }
  scope :checkbox_type, -> { where(data_type: 'RepositoryChecklistValue') }

  def self.name_like(query)
    where('repository_columns.name ILIKE ?', "%#{query}%")
  end

  # Add enum check method with underscores (eg repository_list_value)
  data_types.each do |k, _|
    define_method "#{k.underscore}?" do
      public_send "#{k}?"
    end
  end

  def update_repository_table_states_with_new_column
    service = RepositoryTableStateColumnUpdateService.new
    service.update_states_with_new_column(repository)
  end

  def update_repository_table_states_with_removed_column
    # Calculate old_column_index - this can only be done before
    # record is deleted when we still have its index
    old_column_index = (
      Constants::REPOSITORY_TABLE_DEFAULT_STATE['length'] +
      repository.repository_columns
                .order(id: :asc)
                .pluck(:id)
                .index(id)
    )

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
