module Api
  module V20170715
    class CoreApiController < ApiController
      include PermissionHelper

      def tasks_tree
        teams_json = []
        current_user.teams.find_each do |tm|
          team = team_json(tm)
          projects = []
          tm.projects.find_each do |pr|
            project = project_json(pr)
            experiments = []
            pr.experiments.find_each do |exp|
              experiment = experiment_json(exp)
              tasks = []
              exp.my_modules.find_each do |tk|
                tasks << task_json(tk)
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
        return render json: {}, status: :forbidden unless can_view_module(task)
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

      private

      def team_json(tm)
        team = {}
        team['team_id'] = tm.id.to_s
        team['name'] = tm.name
        team['description'] = tm.description
        team
      end

      def project_json(pr)
        project = {}
        project['project_id'] = pr.id.to_s
        project['name'] = pr.name
        project['visibility'] = pr.visibility
        project['archived'] = pr.archived
        project
      end

      def experiment_json(exp)
        experiment = {}
        experiment['experiment_id'] = exp.id.to_s
        experiment['name'] = exp.name
        experiment['description'] = exp.description
        experiment['archived'] = exp.archived
        experiment
      end

      def task_json(tk)
        task = {}
        task['task_id'] = tk.id.to_s
        task['name'] = tk.name
        task['description'] = tk.description
        task['archived'] = tk.archived
        task
      end
    end
  end
end
