# frozen_string_literal: true

module Api
  module Service
    class ManuscriptDataController < BaseController

      def get_data
        raise ActionController::ParameterMissing, 
              I18n.t('api.service.errors.callback_missing') unless params.require(:callback_url)
        experiment_ids = []
        task_ids = []
        experiment_data_params.each do |experiment|
          experiment_ids.push experiment[:id]
          if experiment.include?('task')
            task_ids += experiment[:task]
          end
        end

        # check if user have permission to read experiment
        experiments = Experiment.includes(:project)
                                 .where(id: experiment_ids)
        experiments.find_each do |exp|
          raise PermissionError.new(Experiment, :read) unless can_read_experiment?(exp)
        end
        
        GenerateManuscriptDataJob.perform_later(experiment_ids, task_ids, params[:callback_url])
        render json: { status: :ok }, status: :accepted
      end

      private

      def experiment_data_params
        raise ActionController::ParameterMissing, 
              I18n.t('api.service.errors.missing_data') unless params.require(:data).require(:experiments)
        params[:data][:experiments]
      end
    end
  end
end
