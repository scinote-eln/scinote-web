# frozen_string_literal: true

class RepositoryDateTimeRangeValueBase < ApplicationRecord
  self.table_name = 'repository_date_time_range_values'

  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User', optional: true,
             inverse_of: :created_repository_date_time_values
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User', optional: true,
             inverse_of: :modified_repository_date_time_values
  has_one :repository_cell, as: :value, dependent: :destroy, inverse_of: :value
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, :start_time, :end_time, :type, presence: true

  SORTABLE_COLUMN_NAME = 'repository_date_time_range_values.start_time'

  def data
    [start_time, end_time].compact.join(' - ')
  end

  def formatted(format)
    [
      I18n.l(start_time, format: format),
      I18n.l(end_time, format: format)
    ].compact.join(' - ')
  end

  def update_data!(new_data, user)
    data = new_data.is_a?(String) ? JSON.parse(new_data).symbolize_keys : new_data
    self.start_time = Time.zone.parse(data[:start_time])
    self.end_time = Time.zone.parse(data[:end_time])
    self.last_modified_by = user
    save!
  end

  def snapshot!(cell_snapshot)
    value_snapshot = dup
    value_snapshot.assign_attributes(
      repository_cell: cell_snapshot,
      created_at: created_at,
      updated_at: updated_at
    )
    value_snapshot.save!
  end
end
