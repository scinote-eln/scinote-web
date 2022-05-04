# frozen_string_literal: true

module Api
  module Service
    class ProjectsJsonExportController < BaseController
      require 'uri'

      def projects_json_export
        @experiment_ids = []
        @task_ids = []
        projects_json_export_params = projects_json_export_data_params
        valid_url?(projects_json_export_params[:callback_url])
        process_projects(projects_json_export_params)
        ProjectsJsonExportJob.perform_later(projects_json_export_params[:project_id],
                                           @experiment_ids,
                                           @task_ids,
                                           projects_json_export_params[:callback_url])
        render json: { status: :ok }, status: :accepted
      end

      private

      def process_projects(projects_json_export_params)
        check_read_project_permission(projects_json_export_params[:project_id])
        if projects_json_export_params.include?('experiments')
          projects_json_export_params[:experiments].each do |experiment|
            check_read_experiment_permission(experiment[:id], projects_json_export_params[:project_id])
            if experiment.include?('task_ids')
              check_read_my_module_permission(experiment[:task_ids], experiment[:id])
              @task_ids += experiment[:task_ids]
            end
            @experiment_ids.push experiment[:id]
          end
        end
      end

      def check_read_project_permission(id)
        project = Project.find(id)
        raise PermissionError.new(Project, :read) unless can_read_project?(project)
      end

      def check_read_experiment_permission(experiment_id, project_id)
        experiment = Experiment.find(experiment_id)
        raise PermissionError.new(Experiment, :read) unless
          can_read_experiment?(experiment) && experiment.project_id == project_id
      end

      def check_read_my_module_permission(task_ids, experiment_id)
        task_ids.each do |task_id|
          task = MyModule.find(task_id)
          raise PermissionError.new(MyModule, :read) unless
            can_read_my_module?(task) && task.experiment_id == experiment_id
        end
      end

      def projects_json_export_data_params
        raise ActionController::ParameterMissing, I18n.t('api.service.errors.missing_task_ids') unless
          params.require(:data).require(:task_ids)
        raise ActionController::ParameterMissing, I18n.t('api.service.errors.callback_missing') unless
          params.require(:data).require(:callback_url)

        params.require(:data).permit(:callback_url, task_ids: [])
      end

      def valid_url?(url)
        uri = URI.parse(url)
        raise URI::InvalidURIError if uri.host.blank?
      end
    end
  end
end
