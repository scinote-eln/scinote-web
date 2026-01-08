# frozen_string_literal: true

class RepositoryRow < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include SearchableModel
  include SearchableByNameModel
  include ArchivableModel

  ID_PREFIX = 'IT'
  include PrefixedIdModel

  SEARCHABLE_ATTRIBUTES = ['repository_rows.name', 'users.full_name', RepositoryRow::PREFIXED_ID_SQL, :children].freeze

  belongs_to :repository, class_name: 'RepositoryBase', counter_cache: :repository_rows_count
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
  belongs_to :my_module, optional: true
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
  has_many :discarded_storage_location_repository_rows,
           -> { discarded },
           class_name: 'StorageLocationRepositoryRow',
           inverse_of: :repository_row,
           dependent: :destroy
  has_many :storage_location_repository_rows, inverse_of: :repository_row, dependent: :destroy
  has_many :storage_locations, through: :storage_location_repository_rows
  has_many :protocol_repository_rows, dependent: :nullify

  auto_strip_attributes :name, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :created_by, presence: true

  attr_accessor :import_status, :import_message, :snapshot_at, :snapshot_by_id, :snapshot_by_name

  scope :active, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  scope :with_active_reminders, lambda { |repository, user|
    left_outer_joins_active_reminders(repository, user).where.not(repository_cells_with_active_reminders: { id: nil })
  }

  scope :filtered_by_column_value, lambda { |repository_column, filter_params|
    value_class_name = repository_column.data_type
    value_class = value_class_name.constantize
    value_type = value_class_name.underscore

    repository_rows =
      repository_column.repository_rows
                       .joins(
                         "INNER JOIN repository_cells AS #{value_type}_cells " \
                         "ON repository_rows.id = #{value_type}_cells.repository_row_id " \
                         "AND #{value_type}_cells.repository_column_id = '#{repository_column.id}' "
                       ).joins(
                         "INNER JOIN #{value_type.pluralize} AS values " \
                         "ON values.id = #{value_type}_cells.value_id"
                       )

    repository_rows = value_class.add_filter_condition(
      repository_rows,
      'values',
      RepositoryTableFilterElement.new(
        operator: filter_params[:operator],
        repository_column: repository_column,
        parameters: filter_params
      )
    )

    where(id: repository_rows.select(:id))
  }

  def code
    "#{ID_PREFIX}#{parent_id || id}"
  end

  def self.readable_by_user(user, teams)
    where(repository: Repository.readable_by_user(user, teams))
  end

  def self.search(user,
                  include_archived,
                  query = nil,
                  teams = user.teams,
                  _options = {})
    repository_rows = joins(:repository, :created_by).readable_by_user(user, teams)
    repository_rows = repository_rows.active unless include_archived
    repository_rows.where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query)
  end

  def self.where_children_attributes_like(query)
    query_clauses = []
    Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each_value do |config|
      query_clauses << unscoped.joins(config[:includes]).where_attributes_like(config[:field], query).to_sql
    end
    unscoped.from("(#{query_clauses.join(' UNION ')}) AS repository_rows", :repository_rows)
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

  def self.left_outer_joins_active_reminders(repository, user)
    repository_cells = RepositoryCell.joins("INNER JOIN repository_columns ON repository_columns.id = repository_cells.repository_column_id AND " \
                                            "repository_columns.repository_id = #{repository.id}")
    joins(
      "LEFT OUTER JOIN (#{repository_cells.with_active_reminder(user).select(:id, :repository_row_id).to_sql}) " \
      "AS repository_cells_with_active_reminders " \
      "ON repository_cells_with_active_reminders.repository_row_id = repository_rows.id"
    )
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

  def output?
    my_module_id.present?
  end
end
