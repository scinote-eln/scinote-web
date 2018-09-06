# frozen_string_literal: true

module Api
  module V1
    class ExperimentSerializer < ActiveModel::Serializer
      type :experiment
      attributes :id, :name, :description, :project_id, :created_by_id,
                 :archived, :created_at, :updated_at
      has_many :my_modules, key: :my_module,
                                  serializer: MyModuleSerializer,
                                  class_name: 'MyModule'
      has_many :my_module_groups, key: :my_module_group,
                                  serializer: MyModuleGroupSerializer,
                                  class_name: 'MyModuleGroup'
      #link(:related) { api_v1_team_project_experiment_path(@experiment) }
    end
  end
end
