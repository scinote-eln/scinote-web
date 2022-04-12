# frozen_string_literal: true

module Api
  module Service
    class ManuscriptDataController < BaseController
      require 'uri'

      def get_data
        @experiment_ids = []
        @task_ids = []
        manuscript_params = manuscript_data_params
        valid_url?(manuscript_data_params[:callback_url])
        manuscript_params[:experiments].each do |experiment|
          process_experiment(experiment)
        end
        GenerateManuscriptDataJob.perform_later(@experiment_ids, @task_ids, manuscript_params[:callback_url])
        render json: { status: :ok }, status: :accepted
      end

      private

      def process_experiment(experiment)
        check_read_experiment_permission(Experiment.find_by(id: experiment[:id]))
        if experiment.include?('task')
          check_read_my_module_permission(experiment[:task], experiment[:id])
          @task_ids += experiment[:task]
        end
        @experiment_ids.push experiment[:id]
      end

      def check_read_experiment_permission(id)
        experiment = Experiment.find_by(id: id)
        raise PermissionError.new(Experiment, :read) unless can_read_experiment?(experiment)
      end

      def check_read_my_module_permission(task_ids, experiment_id)
        task_ids.each do |task_id|
          task = MyModule.find_by(id: task_id)
          raise PermissionError.new(MyModule, :read) unless can_read_my_module?(task) && task.experiment_id == experiment_id
        end
      end

      def manuscript_data_params
        raise ActionController::ParameterMissing, 
              I18n.t('api.service.errors.callback_missing') unless params.require(:data).require(:callback_url)
        raise ActionController::ParameterMissing, 
              I18n.t('api.service.errors.missing_data') unless params.require(:data).require(:experiments)
        params.require(:data).permit(:callback_url, experiments: [:id, task:[]])
      end

      def valid_url?(url)
        uri = URI.parse(url)
        raise URI::InvalidURIError unless uri.host.present?
      end
    end
  end
end
