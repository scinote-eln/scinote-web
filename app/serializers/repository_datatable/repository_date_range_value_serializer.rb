# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateRangeValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      date_time_format = @instance_options[:user].settings[:date_format]
      cell = object.repository_date_time_range_value
      cell.start_time.strftime(date_time_format) + ' - ' + cell.end_time.strftime(date_time_format)
    end
  end
end
