module Api
  module V20170715
    class CoreApiController < ApiController
      def tasks_tree
        teams_json = []
        current_user.teams.find_each do |tm|
          team = tm.as_json(only: %i(name description))
          team['team_id'] = tm.id.to_s
          projects = []
          tm.projects.find_each do |pr|
            project = pr.as_json(only: %i(name visibility archived))
            project['project_id'] = pr.id.to_s
            experiments = []
            pr.experiments.find_each do |exp|
              experiment = exp.as_json(only: %i(name description archived))
              experiment['experiment_id'] = exp.id.to_s
              tasks = []
              exp.my_modules.find_each do |tk|
                task = tk.as_json(only: %i(name description archived))
                task['task_id'] = tk.id.to_s
                task['editable'] = can_manage_module?(tk)
                tasks << task
              end
              experiment['tasks'] = tasks
              experiments << experiment
            end
            project['experiments'] = experiments
            projects << project
          end
          team['projects'] = projects
          teams_json << team
        end
        render json: teams_json, status: :ok
      end

    end
  end
end
