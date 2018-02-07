module Api
  module V20170715
    class CoreApiController < ApiController
      include PermissionHelper

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

      def task_samples
        task = MyModule.find_by_id(params[:task_id])
        return render json: {}, status: :not_found unless task
        return render json: {}, status: :forbidden unless
          can_read_experiment?(task.experiment)
        samples = task.samples
        samples_json = []
        samples.find_each do |s|
          sample = {}
          sample['sample_id'] = s.id.to_s
          sample['name'] = s.name
          samples_json << sample
        end
        render json: samples_json, status: :ok
      end
    end
  end
end
