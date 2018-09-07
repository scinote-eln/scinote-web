# frozen_string_literal: true

module Api
  module V1
    class MyModuleGroupSerializer < ActiveModel::Serializer
      type :task_groups
      attributes :id, :created_at, :updated_at, :created_by_id, :experiment_id
      belongs_to :experiment, serializer: ExperimentSerializer
    end
  end
end
