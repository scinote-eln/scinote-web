# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryBaseValueSerializer < ActiveModel::Serializer
    attributes :value, :value_type

    def value
      raise NotImplementedError
    end

    def value_type
      object.class.name
    end
  end
end
