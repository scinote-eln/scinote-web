# frozen_string_literal: true

module Api
  module V1
    class ActivitiesController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_project_activity, only: :project_activity
      before_action :load_experiment, except: %i(
        project_activities project_activity
      )
      before_action :load_task, except: %i(project_activities project_activity)
      before_action :load_activity, only: :show

      def index
        activities = @my_module.activities
                               .page(params.dig(:page, :number))
                               .per(params.dig(:page, :size))

        render jsonapi: activities,
          each_serializer: ActivitySerializer
      end

      def show
        render jsonapi: @activity, serializer: ActivitySerializer
      end

      def project_activities
        activities = @project.activities
                             .page(params.dig(:page, :number))
                             .per(params.dig(:page, :size))

        render jsonapi: activities,
          each_serializer: ActivitySerializer
      end

      def project_activity
        render jsonapi: @project_activity, serializer: ActivitySerializer
      end

      private

      def load_team
        @team = Team.find(params.require(:team_id))
        render jsonapi: {}, status: :forbidden unless can_read_team?(@team)
      end

      def load_project
        @project = @team.projects.find(params.require(:project_id))
        render jsonapi: {}, status: :forbidden unless can_read_project?(
          @project
        )
      end

      def load_experiment
        @experiment = @project.experiments.find(params.require(:experiment_id))
        render jsonapi: {}, status: :forbidden unless can_read_experiment?(
          @experiment
        )
      end

      def load_task
        @my_module = @experiment.my_modules.find(params.require(:task_id))
        render jsonapi: {}, status: :not_found if @my_module.nil?
      end

      def load_activity
        @activity = @my_module.activities.find(
          params.require(:id)
        )
        render jsonapi: {}, status: :not_found if @activity.nil?
      end

      def load_project_activity
        @project_activity = @project.activities.find(
          params.require(:id)
        )
        render jsonapi: {}, status: :not_found if @project_activity.nil?
      end
    end
  end
end
