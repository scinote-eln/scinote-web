# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateTimeRangeValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      cell = object.repository_date_time_range_value
      I18n.l(cell.start_time, format: :full_with_comma) + ' - ' + I18n.l(cell.end_time, format: :full_with_comma)
    end
  end
end
