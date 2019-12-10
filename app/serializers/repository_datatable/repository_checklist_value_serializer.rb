# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryChecklistValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      object.repository_checklist_value.data
    end
  end
end
