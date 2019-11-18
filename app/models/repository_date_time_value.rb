# frozen_string_literal: true

class RepositoryDateTimeValue < ApplicationRecord
  enum datetime_type: { datetime: 0, date: 1, time: 2, datetime_range: 3, date_range: 4, time_range: 5 }

  belongs_to :created_by, foreign_key: :created_by_id, class_name: 'User', optional: true,
             inverse_of: :created_repositroy_date_time_values
  belongs_to :last_modified_by, foreign_key: :last_modified_by_id, class_name: 'User', optional: true,
             inverse_of: :modified_repositroy_date_time_values
  has_one :repository_cell, as: :value, dependent: :destroy
  accepts_nested_attributes_for :repository_cell

  validates :repository_cell, :datetime_type, :start_time, presence: true
  validates :end_time, presence: true, if: ->(record) { record.datetime_type.to_s.include?('_range') }
  validates :end_time, absence: true, unless: ->(record) { record.datetime_type.to_s.include?('_range') }
end
