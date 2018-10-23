# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApiController
      class TypeError < StandardError; end
      class IDMismatchError < StandardError; end

      rescue_from StandardError do |e|
        logger.error e.message
        logger.error e.backtrace.join("\n")
        render_error(I18n.t('api.core.errors.general.title'),
                     I18n.t('api.core.errors.general.detail'),
                     :bad_request)
      end

      rescue_from TypeError do
        render_error(I18n.t('api.core.errors.type.title'),
                     I18n.t('api.core.errors.type.detail'),
                     :bad_request)
      end

      rescue_from IDMismatchError do
        render_error(I18n.t('api.core.errors.id_mismatch.title'),
                     I18n.t('api.core.errors.id_mismatch.detail'),
                     :bad_request)
      end

      rescue_from ActionController::ParameterMissing do |e|
        render_error(
          I18n.t('api.core.errors.parameter.title'), e.message, :bad_request
        )
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        render_error(
          I18n.t('api.core.errors.record_not_found.title'),
          I18n.t('api.core.errors.record_not_found.detail',
                 model: e.model,
                 id: e.id),
          :not_found
        )
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_error(
          I18n.t('api.core.errors.validation.title'), e.message, :bad_request
        )
      end

      private

      def render_error(title, message, status)
        logger.error message
        render json: {
          errors: [
            {
              id: request.uuid,
              status: Rack::Utils.status_code(status),
              title: title,
              detail: message
            }
          ]
        }, status: status
      end

      def permission_error(klass, mode)
        model = klass.name.underscore
        render_error(
          I18n.t("api.core.errors.#{mode}_permission.title"),
          I18n.t("api.core.errors.#{mode}_permission.detail", model: model),
          :forbidden
        )
      end

      def load_team
        @team = Team.find(params.require(:team_id))
        permission_error(Team, :read) unless can_read_team?(@team)
      end

      def load_inventory
        @inventory = @team.repositories.find(params.require(:inventory_id))
      end

      def load_inventory_column
        @inventory_column = @inventory.repository_columns
                                      .find(inventory_cell_params[:column_id])
      end

      def load_project
        @project = @team.projects.find(params.require(:project_id))
        permission_error(Project, :read) unless can_read_project?(@project)
      end

      def load_experiment
        @experiment = @project.experiments.find(params.require(:experiment_id))
        permission_error(Experiment, :read) unless can_read_experiment?(
          @experiment
        )
      end

      def load_task
        @task = @experiment.my_modules.find(params.require(:task_id))
      end
    end
  end
end
