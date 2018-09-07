# frozen_string_literal: true

module Api
  module V1
    class MyModuleSerializer < ActiveModel::Serializer
      type :tasks
      attributes :id, :name, :due_date, :description,
                 :my_module_group_id, :nr_of_assigned_samples, :state
      belongs_to :experiment, serializer: ExperimentSerializer
    end
  end
end
