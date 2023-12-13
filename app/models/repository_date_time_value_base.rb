# frozen_string_literal: true

class RepositoryDateTimeValueBase < ApplicationRecord
  self.table_name = 'repository_date_time_values'

  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User', optional: true,
             inverse_of: :created_repository_date_time_values
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User', optional: true,
             inverse_of: :modified_repository_date_time_values
  has_one :repository_cell, as: :value, dependent: :destroy
  accepts_nested_attributes_for :repository_cell
  before_save :reset_notification_sent, if: -> { data_changed? }

  validates :repository_cell, :data, :type, presence: true

  SORTABLE_COLUMN_NAME = 'repository_date_time_values.data'

  def formatted(format)
    I18n.l(data, format: format)
  end

  def update_data!(new_data, user)
    self.data = Time.zone.parse(new_data)
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

  private

  def reset_notification_sent
    self.notification_sent = false
  end
end
