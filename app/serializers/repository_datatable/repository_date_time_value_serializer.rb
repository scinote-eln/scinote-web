# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateTimeValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      date_time_format = @instance_options[:user].settings[:date_format] + ', %H:%M'
      cell = object.repository_date_time_value
      cell.data.strftime(date_time_format)
    end
  end
end
