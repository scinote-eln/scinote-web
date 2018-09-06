# frozen_string_literal: true

module Api
  module V1
    class MyModuleSerializer < ActiveModel::Serializer
      type :task
      attributes :id, :name, :due_date, :description, :my_module_group_id, :nr_of_assigned_samples, :state
      link(:self) {
        api_v1_team_project_experiment_task_url(
          return_path[0], return_path[1], return_path[2], object.id
        )
      }
      belongs_to :experiment

      def return_path
        return_array = []
        experiment = object.experiment
        project = experiment.project
        team = project.team
        return_array.push(experiment, project, team)
        return_array
      end
    end
  end
end
