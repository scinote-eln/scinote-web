# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryBaseValueSerializer
    attr_accessor :value_object, :value_type, :scope

    def initialize(value, scope:)
      @value_object = value
      @value_type = value.class.name
      @scope = scope
    end

    def serializable_hash
      {
        value: value,
        value_type: @value_type
      }
    end

    def value
      raise NotImplementedError
    end
  end
end
