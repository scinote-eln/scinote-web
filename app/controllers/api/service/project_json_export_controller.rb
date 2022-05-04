# frozen_string_literal: true

module Api
  module Service
    class ProjectJsonExportController < BaseController
      require 'uri'

      def project_json_export
        @experiment_ids = []
        @task_ids = []
        project_json_export_params = project_json_export_data_params
        valid_url?(project_json_export_params[:callback_url])
        process_project(project_json_export_params)
        ProjectJsonExportJob.perform_later(project_json_export_params[:project_id],
                                           @experiment_ids,
                                           @task_ids,
                                           project_json_export_params[:callback_url])
        render json: { status: :ok }, status: :accepted
      end

      private

      def process_project(project_json_export_params)
        check_read_project_permission(project_json_export_params[:project_id])
        if project_json_export_params.include?('experiments')
          project_json_export_params[:experiments].each do |experiment|
            check_read_experiment_permission(experiment[:id], project_json_export_params[:project_id])
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

      def project_json_export_data_params
        raise ActionController::ParameterMissing, I18n.t('api.service.errors.missing_project_id') unless
          params.require(:data).require(:project_id)
        raise ActionController::ParameterMissing, I18n.t('api.service.errors.callback_missing') unless
          params.require(:data).require(:callback_url)

        params.require(:data).permit(:callback_url, :project_id, experiments: [:id, task_ids: []])
      end

      def valid_url?(url)
        uri = URI.parse(url)
        raise URI::InvalidURIError if uri.host.blank?
      end
    end
  end
end
