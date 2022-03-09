# frozen_string_literal: true

class RepositoryRow < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel
  include ArchivableModel
  include ReminderRepositoryCellJoinable

  ID_PREFIX = 'IT'
  include PrefixedIdModel

  belongs_to :repository, class_name: 'RepositoryBase'
  belongs_to :parent, class_name: 'RepositoryRow', optional: true
  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User'
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User'
  belongs_to :archived_by,
             class_name: 'User',
             inverse_of: :archived_repository_rows,
             optional: true
  belongs_to :restored_by,
             class_name: 'User',
             inverse_of: :restored_repository_rows,
             optional: true
  has_many :repository_cells, -> { order(:id) }, inverse_of: :repository_row, dependent: :destroy

  {
    repository_text: 'RepositoryTextValue',
    repository_number: 'RepositoryNumberValue',
    repository_list: 'RepositoryListValue',
    repository_asset: 'RepositoryAssetValue',
    repository_status: 'RepositoryStatusValue',
    repository_checklist: 'RepositoryChecklistValue',
    repository_date_time: 'RepositoryDateTimeValue',
    repository_time: 'RepositoryTimeValue',
    repository_date: 'RepositoryDateValue',
    repository_date_time_range: 'RepositoryDateTimeRangeValue',
    repository_time_range: 'RepositoryTimeRangeValue',
    repository_date_range: 'RepositoryDateRangeValue',
    repository_stock: 'RepositoryStockValue'
  }.each do |relation, class_name|
    has_many "#{relation}_cells".to_sym, -> { where(value_type: class_name) }, class_name: 'RepositoryCell',
             inverse_of: :repository_row
    has_many "#{relation}_values".to_sym, class_name: class_name, through: "#{relation}_cells".to_sym,
             source: :value, source_type: class_name
  end

  has_one :repository_stock_cell,
          lambda {
            joins(:repository_column)
              .where(repository_columns: { data_type: 'RepositoryStockValue' })
              .where(value_type: 'RepositoryStockValue')
          },
          class_name: 'RepositoryCell',
          inverse_of: :repository_row
  has_one :repository_stock_value, class_name: 'RepositoryStockValue',
          through: :repository_stock_cell,
          source: :value,
          source_type: 'RepositoryStockValue'

  # Only in snapshots
  has_one :repository_stock_consumption_cell,
          lambda {
            joins(:repository_column)
              .where(repository_columns: { data_type: 'RepositoryStockConsumptionValue' })
              .where(value_type: 'RepositoryStockValue')
          },
          class_name: 'RepositoryCell',
          inverse_of: :repository_row
  has_one :repository_stock_consumption_value,
          class_name: 'RepositoryStockConsumptionValue',
          through: :repository_stock_consumption_cell,
          source: :value,
          source_type: 'RepositoryStockValue'

  has_many :repository_columns, through: :repository_cells
  has_many :my_module_repository_rows,
           inverse_of: :repository_row, dependent: :destroy
  has_many :my_modules, through: :my_module_repository_rows

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :created_by, presence: true

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  scope :with_active_reminders, lambda {
    reminder_repository_cells_scope(joins(repository_cells: :repository_column)).distinct
  }

  def code
    "#{ID_PREFIX}#{parent_id || id}"
  end

  def self.viewable_by_user(user, teams)
    where(repository: Repository.viewable_by_user(user, teams))
  end

  def self.name_like(query)
    where('repository_rows.name ILIKE ?', "%#{query}%")
  end

  def self.change_owner(team, user, new_owner)
    joins(:repository)
      .where('repositories.team_id = ? and repository_rows.created_by_id = ?', team, user)
      .update_all(created_by_id: new_owner.id)
  end

  def editable?
    true
  end

  def row_archived?
    self[:archived]
  end

  def archived
    row_archived? || repository&.archived?
  end

  def archived?
    row_archived? ? super : repository.archived?
  end

  def archived_by
    row_archived? ? super : repository.archived_by
  end

  def archived_on
    row_archived? ? super : repository.archived_on
  end

  def has_stock?
    RepositoryStockValue.joins(repository_cell: :repository_row).exists?(repository_rows: { id: id })
  end

  def snapshot!(repository_snapshot)
    row_snapshot = dup
    row_snapshot.assign_attributes(
      repository: repository_snapshot,
      parent_id: id,
      created_at: created_at,
      updated_at: updated_at
    )
    row_snapshot.save!

    repository_cells.each { |cell| cell.snapshot!(row_snapshot) }
    row_snapshot
  end
end
