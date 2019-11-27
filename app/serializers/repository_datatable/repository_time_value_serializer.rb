# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryTimeValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      date_time_format = '%H:%M'
      cell = object.repository_date_time_value
      cell.data.strftime(date_time_format)
    end
  end
end
