# frozen_string_literal: true

module Api
  module Service
    class BaseController < ApiController
      class TypeError < StandardError; end

      class PermissionError < StandardError
        attr_reader :klass, :mode

        def initialize(klass, mode)
          @klass = klass
          @mode = mode
        end
      end

      rescue_from StandardError do |e|
        logger.error e.message
        logger.error e.backtrace.join("\n")
        render_error(I18n.t('api.core.errors.general.title'),
                     I18n.t('api.core.errors.general.detail'),
                     :bad_request)
      end

      rescue_from PermissionError do |e|
        model = e.klass.name.underscore
        render_error(
          I18n.t("api.core.errors.#{e.mode}_permission.title"),
          I18n.t("api.core.errors.#{e.mode}_permission.detail", model: model),
          :forbidden
        )
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

      rescue_from URI::InvalidURIError do
        render_error(
          I18n.t('api.service.errors.url.not_valid'),
          I18n.t('api.service.errors.url.not_valid'), :bad_request
        )
      end

      rescue_from JWT::DecodeError,
                  JWT::InvalidPayload,
                  JWT::VerificationError,
                  JWT::ExpiredSignature do |e|
        render_error(
          I18n.t('api.core.invalid_token'), e.message, :unauthorized
        )
      end

      private

      def load_team
        @team = current_user.teams.find(params.require(:team_id))
        raise PermissionError.new(Team, :read) unless can_read_team?(@team)
      end

      def load_project(key = :project_id)
        @project = @team.projects.find(params.require(key))
        raise PermissionError.new(Project, :read) unless can_read_project?(@project)
      end

      def load_experiment(key = :experiment_id)
        @experiment = @project.experiments.find(params.require(key))
        raise PermissionError.new(Experiment, :read) unless can_read_experiment?(@experiment)
      end

      def load_task(key = :task_id)
        @task = @experiment.my_modules.find(params.require(key))
        raise PermissionError.new(MyModule, :read) unless can_read_my_module?(@task)
      end

      def load_protocol(key = :protocol_id)
        @protocol = @task.protocols.find(params.require(key))
        raise PermissionError.new(Protocol, :read) unless can_read_protocol_in_module?(@protocol)
      end

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
    end
  end
end
