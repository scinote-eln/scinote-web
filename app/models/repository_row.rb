# frozen_string_literal: true

class RepositoryRow < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include SearchableModel
  include SearchableByNameModel
  include ArchivableModel
  include ReminderRepositoryCellJoinable

  ID_PREFIX = 'IT'
  include PrefixedIdModel

  belongs_to :repository, class_name: 'RepositoryBase'
  delegate :team, to: :repository
  belongs_to :parent, class_name: 'RepositoryRow', optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'
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
    repository_stock: 'RepositoryStockValue',
    repository_date_time: 'RepositoryDateTimeValueBase',
    repository_time: 'RepositoryDateTimeValueBase',
    repository_date: 'RepositoryDateTimeValueBase',
    repository_date_time_range: 'RepositoryDateTimeRangeValueBase',
    repository_time_range: 'RepositoryDateTimeRangeValueBase',
    repository_date_range: 'RepositoryDateTimeRangeValueBase'
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

  has_many :repository_columns, through: :repository_cells, dependent: :destroy
  has_many :my_module_repository_rows,
           inverse_of: :repository_row, dependent: :destroy
  has_many :my_modules, through: :my_module_repository_rows, dependent: :destroy
  has_many :child_connections,
           class_name: 'RepositoryRowConnection',
           foreign_key: :parent_id,
           dependent: :destroy,
           inverse_of: :parent
  has_many :child_repository_rows,
           through: :child_connections,
           class_name: 'RepositoryRow',
           source: :child,
           dependent: :destroy
  has_many :parent_connections,
           class_name: 'RepositoryRowConnection',
           foreign_key: :child_id,
           dependent: :destroy,
           inverse_of: :child
  has_many :parent_repository_rows,
           through: :parent_connections,
           class_name: 'RepositoryRow',
           source: :parent,
           dependent: :destroy
  has_many :storage_location_repository_rows, inverse_of: :repository_row, dependent: :destroy
  has_many :storage_locations, through: :storage_location_repository_rows

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :created_by, presence: true

  attr_accessor :import_status, :import_message

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  scope :with_active_reminders, lambda { |user|
    reminder_repository_cells_scope(joins(:repository_cells), user)
  }

  def code
    "#{ID_PREFIX}#{parent_id || id}"
  end

  def self.viewable_by_user(user, teams)
    where(repository: Repository.viewable_by_user(user, teams))
  end

  def self.search(user,
                  include_archived,
                  query = nil,
                  _current_team = nil,
                  options = {})

    teams = options[:teams] || current_team || user.teams.select(:id)
    searchable_row_fields = [RepositoryRow::PREFIXED_ID_SQL, 'repository_rows.name', 'users.full_name']

    readable_rows = distinct.joins(:repository, :created_by)
                            .joins("INNER JOIN user_assignments repository_user_assignments " \
                                   "ON repository_user_assignments.assignable_type = 'RepositoryBase' " \
                                   "AND repository_user_assignments.assignable_id = repositories.id")
                            .where(repository_user_assignments: { user_id: user, team_id: teams })

    readable_rows = readable_rows.active unless include_archived
    repository_rows = readable_rows.where_attributes_like_boolean(searchable_row_fields, query, options)

    Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each do |_data_type, config|
      custom_cell_matches = readable_rows.joins(config[:includes])
                                         .where_attributes_like_boolean(config[:field], query, options)
      repository_rows = repository_rows.or(readable_rows.where(id: custom_cell_matches))
    end

    repository_rows
  end

  def self.filter_by_teams(teams = [])
    return self if teams.blank?

    joins(:repository).where(repository: { team: teams })
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

  def row_consumption(stock_consumption)
    if repository_stock_cell.present?
      consumed_stock = number_with_precision(
        stock_consumption || 0,
        precision: (repository.repository_stock_column.metadata['decimals'].to_i || 0),
        strip_insignificant_zeros: true
      )
      "#{consumed_stock} #{repository_stock_value&.repository_stock_unit_item&.data}"
    else
      '-'
    end
  end

  def relationship_count
    parent_connections.size + child_connections.size
  end

  def archived_branch?
    archived?
  end
end
