# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApiController
      class TypeError < StandardError; end

      class IDMismatchError < StandardError; end

      class IncludeNotSupportedError < StandardError; end

      class FilterParamError < StandardError; end

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

      rescue_from FilterParamError do |e|
        logger.error e.message
        logger.error e.backtrace.join("\n")
        render_error(I18n.t('api.core.errors.filter_parameter.title'),
                     I18n.t('api.core.errors.filter_parameter.detail'),
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

      rescue_from NotImplementedError do
        render_error(I18n.t('api.core.errors.not_implemented.title'),
                     I18n.t('api.core.errors.not_implemented.detail'),
                     :bad_request)
      end

      rescue_from IncludeNotSupportedError do
        render_error(I18n.t('api.core.errors.include_not_supported.title'),
                     I18n.t('api.core.errors.include_not_supported.detail'),
                     :bad_request)
      end

      rescue_from ActionController::BadRequest do |e|
        render_error(
          I18n.t('api.core.errors.parameter_incorrect.title'), e.message, :bad_request
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

      rescue_from JWT::DecodeError,
                  JWT::InvalidPayload,
                  JWT::VerificationError,
                  JWT::ExpiredSignature do |e|
        render_error(
          I18n.t('api.core.invalid_token'), e.message, :unauthorized
        )
      end

      before_action :check_include_param, only: %i(index show)

      def index
        raise NotImplementedError
      end

      def show
        raise NotImplementedError
      end

      def create
        raise NotImplementedError
      end

      def update
        raise NotImplementedError
      end

      def destroy
        raise NotImplementedError
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

      def check_include_param
        return if params[:include].blank?

        include_params
      end

      # redefine it in the specific controller if includes are used there
      def permitted_includes
        []
      end

      def include_params
        return nil if params[:include].blank?

        provided_includes = params[:include].split(',')
        raise IncludeNotSupportedError if (provided_includes - permitted_includes).any?

        provided_includes
      end

      def load_team(key = :team_id)
        @team = Team.find(params.require(key))
        current_user.permission_team = @team
        raise PermissionError.new(Team, :read) unless can_read_team?(@team)
      end

      def load_inventory(key = :inventory_id)
        @inventory = @team.repositories.find(params.require(key))
        raise PermissionError.new(Repository, :read) unless can_read_repository?(@inventory)
      end

      def load_inventory_column(key = :column_id)
        @inventory_column = @inventory.repository_columns.find(params.require(key))
      end

      def load_inventory_item(key = :item_id)
        @inventory_item = @inventory.repository_rows.find(params[key])
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

      def load_step(key = :step_id)
        @step = @protocol.steps.find(params.require(key))
        raise PermissionError.new(Protocol, :read) unless can_read_protocol_in_module?(@step.protocol)
      end

      def load_table(key = :table_id)
        @table = @step.tables.find(params.require(key))
        raise PermissionError.new(Protocol, :read) unless can_read_protocol_in_module?(@step.protocol)
      end

      def load_checklist(key = :checklist_id)
        @checklist = @step.checklists.find(params.require(key))
        raise PermissionError.new(Protocol, :read) unless can_read_protocol_in_module?(@step.protocol)
      end

      def load_step_text(key = :step_text_id)
        @step_text = @step.step_texts.find(params.require(key))
        raise PermissionError.new(Protocol, :read) unless can_read_protocol_in_module?(@step.protocol)
      end

      def load_checklist_item(key = :checklist_item_id)
        @checklist_item = @checklist.checklist_items.find(params.require(key))
        raise PermissionError.new(Protocol, :read) unless can_read_protocol_in_module?(@step.protocol)
      end

      def load_workflow(key = :workflow_id)
        @workflow = MyModuleStatusFlow.find(params.require(key))
      end

      def archived_filter(archivable_collection)
        return archivable_collection if params.dig(:filter, :archived).blank?

        case params.dig(:filter, :archived)
        when 'false'
          archivable_collection.active
        when 'true'
          archivable_collection.archived
        else
          raise FilterParamError
        end
      end

      def timestamps_filter(records)
        from = Date.parse(params.dig(:filter, :created_at, :from)) if
          params.dig(:filter, :created_at, :from).present?
        to = Date.parse(params.dig(:filter, :created_at, :to)) if
          params.dig(:filter, :created_at, :to).present?
        records = records.where(created_at: (from..to)) if from || to

        from = Date.parse(params.dig(:filter, :updated_at, :from)) if
          params.dig(:filter, :updated_at, :from).present?
        to = Date.parse(params.dig(:filter, :updated_at, :to)) if
          params.dig(:filter, :updated_at, :to).present?
        records = records.where(updated_at: (from..to)) if from || to

        records
      end
    end
  end
end
