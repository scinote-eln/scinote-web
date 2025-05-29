# frozen_string_literal: true

class RepositoryCell < ApplicationRecord
  attr_accessor :importing, :to_destroy

  belongs_to :repository_row, touch: true
  belongs_to :repository_column
  belongs_to :value, polymorphic: true, inverse_of: :repository_cell, dependent: :destroy

  {
    repository_text: 'RepositoryTextValue',
    repository_number: 'RepositoryNumberValue',
    repository_list: 'RepositoryListValue',
    repository_asset: 'RepositoryAssetValue',
    repository_status: 'RepositoryStatusValue',
    repository_checklist: 'RepositoryChecklistValue',
    repository_date_time: 'RepositoryDateTimeValueBase',
    repository_time: 'RepositoryDateTimeValueBase',
    repository_date: 'RepositoryDateTimeValueBase',
    repository_date_time_range: 'RepositoryDateTimeRangeValueBase',
    repository_time_range: 'RepositoryDateTimeRangeValueBase',
    repository_date_range: 'RepositoryDateTimeRangeValueBase',
    repository_stock: 'RepositoryStockValue',
    repository_stock_consumption_snapshot: 'RepositoryStockConsumptionValue'
  }.each do |relation, class_name|
    belongs_to "#{relation}_value".to_sym,
               (lambda do |repository_cell|
                 repository_cell.value_type == class_name ? self : none
               end),
               optional: true, foreign_key: :value_id, inverse_of: :repository_cell
  end

  has_many :hidden_repository_cell_reminders, dependent: :destroy

  validates :repository_column,
            inclusion: { in: (lambda do |repository_cell|
              repository_cell.repository_row&.repository&.repository_columns || []
            end) },
            unless: :importing
  validates :repository_column, presence: true
  validate :repository_column_data_type
  validates :repository_row,
            uniqueness: { scope: :repository_column },
            unless: :importing

  after_touch :update_repository_row_last_modified_by

  scope :with_active_reminder, lambda { |user|
    from(
      "((#{with_active_stock_reminder(user).to_sql}) UNION ALL " \
      "(#{with_active_datetime_reminder(user).to_sql})) AS repository_cells"
    )
  }

  scope :with_active_stock_reminder, lambda { |user|
    joins( # stock reminders
      'LEFT OUTER JOIN "repository_stock_values" ON ' \
      '"repository_cells"."value_type" = \'RepositoryStockValue\' AND ' \
      '"repository_stock_values"."id" = "repository_cells"."value_id" AND ' \
      '(repository_stock_values.amount <= repository_stock_values.low_stock_threshold OR ' \
      'repository_stock_values.amount <= 0)'
    ).joins(
      'LEFT OUTER JOIN "hidden_repository_cell_reminders" ON ' \
      '"repository_cells"."id" = "hidden_repository_cell_reminders"."repository_cell_id" AND ' \
      '"hidden_repository_cell_reminders"."user_id" = ' + user.id.to_s
    ).where(
      'hidden_repository_cell_reminders.id IS NULL AND repository_stock_values.id IS NOT NULL'
    )
  }

  scope :with_active_datetime_reminder, lambda { |user|
    joins(
      'INNER JOIN repository_columns repository_reminder_columns ON ' \
      'repository_reminder_columns.id = repository_cells.repository_column_id'
    ).joins( # datetime reminders
      'LEFT OUTER JOIN "repository_date_time_values" ON ' \
      '"repository_date_time_values"."id" = "repository_cells"."value_id" AND ' \
      '"repository_cells"."value_type" = \'RepositoryDateTimeValueBase\' ' \
      'AND repository_reminder_columns.metadata ->> \'reminder_value\' <> \'\' AND ' \
      'repository_date_time_values.data <= ' \
      '(NOW() AT TIME ZONE \'UTC\') + (repository_reminder_columns.metadata ->> \'reminder_value\')::int * ' \
      '(repository_reminder_columns.metadata ->> \'reminder_unit\')::int * \'1 SECOND\'::interval'
    ).joins(
      'LEFT OUTER JOIN "hidden_repository_cell_reminders" ON ' \
      '"repository_cells"."id" = "hidden_repository_cell_reminders"."repository_cell_id" AND ' \
      '"hidden_repository_cell_reminders"."user_id" = ' + user.id.to_s
    ).where(
      'hidden_repository_cell_reminders.id IS NULL AND repository_date_time_values.id IS NOT NULL'
    )
  }

  def update_repository_row_last_modified_by
    # RepositoryStockConsumptionValue currently don't store last_modified_by
    # so this would fail. Should probably be refactored to unify the behaviour (23.7.2024)
    if value.last_modified_by_id
      repository_row.update!(last_modified_by_id: value.last_modified_by_id)
    else
      Rails.logger.warn(
        "Missing last_modified_by_id for #{value.class} with id #{value.id}, " \
        "skipping update of last_modified_by on RepositoryRow with id #{repository_row_id}."
      )
    end
  end

  def self.create_with_value!(row, column, data, user)
    cell = new(repository_row: row, repository_column: column)
    cell.transaction do
      value_klass = column.data_type.constantize
      value = value_klass.new_with_payload(data, repository_cell: cell,
                                                 created_by: user,
                                                 last_modified_by: user)
      cell.value = value
      value.save!
    end
    cell.reload
  end

  def snapshot!(row_snapshot)
    cell_snapshot = dup
    column_snapshot = row_snapshot.repository
                                  .repository_columns
                                  .find { |c| c.parent_id == repository_column.id }
    cell_snapshot.assign_attributes(
      repository_row: row_snapshot,
      repository_column: column_snapshot,
      created_at: created_at,
      updated_at: updated_at
    )
    value.snapshot!(cell_snapshot)
    cell_snapshot
  end

  private

  def repository_column_data_type
    if !repository_column || value.class.name != repository_column.data_type
      errors.add(:value_type, 'must match column data type')
    end
  end
end
