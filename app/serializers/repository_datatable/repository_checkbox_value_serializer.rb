# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryCheckboxValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      object.repository_checkbox_value.data
    end
  end
end
