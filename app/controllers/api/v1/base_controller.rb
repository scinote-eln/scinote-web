# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApiController
      class TypeError < StandardError; end
      class IDMismatchError < StandardError; end
      class PermissionError < StandardError
        attr_reader :klass
        attr_reader :mode
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

      def load_team(key = :team_id)
        @team = Team.find(params.require(key))
        raise PermissionError.new(Team, :read) unless can_read_team?(@team)
      end

      def load_inventory(key = :inventory_id)
        @inventory = @team.repositories.find(params.require(key))
      end

      def load_inventory_column(key = :column_id)
        @inventory_column = @inventory.repository_columns
                                      .find(params.require(key))
      end

      def load_inventory_item(key = :item_id)
        @inventory_item = @inventory.repository_rows.find(params[key].to_i)
      end

      def load_project(key = :project_id)
        @project = @team.projects.find(params.require(key))
        unless can_read_project?(@project)
          raise PermissionError.new(Project, :read)
        end
      end

      def load_experiment(key = :experiment_id)
        @experiment = @project.experiments.find(params.require(key))
        unless can_read_experiment?(@experiment)
          raise PermissionError.new(Experiment, :read)
        end
      end

      def load_task(key = :task_id)
        @task = @experiment.my_modules.find(params.require(key))
      end
    end
  end
end
