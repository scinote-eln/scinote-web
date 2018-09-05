# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiment
      attributes :id, :name, :description
      has_many :my_modules, key: :my_modules,
                            serializer: MyModuleSerializer,
                            class_name: 'MyModule'
    end
  end
end
