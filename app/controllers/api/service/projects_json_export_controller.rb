# frozen_string_literal: true

module Api
  module Service
    class ProjectsJsonExportController < BaseController
      require 'uri'

      def projects_json_export
        projects_json_export_params = projects_json_export_data_params
        valid_url?(projects_json_export_params[:callback_url])
        ProjectsJsonExportJob.perform_later(projects_json_export_params[:task_ids],
                                            projects_json_export_params[:callback_url],
                                            current_user.id)
        render json: { status: :ok }, status: :accepted
      end

      private

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
