# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryDateValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      cell = object.repository_date_time_value
      I18n.l(cell.data, format: :full_date)
    end
  end
end
