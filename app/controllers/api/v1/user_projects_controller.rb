# frozen_string_literal: true

module Api
  module V1
    class UserProjectsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :load_user_project, only: :show
      before_action :load_user_project_for_managing, only: %i(update destroy)

      def index
        user_projects = @project.user_projects
                                .page(params.dig(:page, :number))
                                .per(params.dig(:page, :size))

        render jsonapi: user_projects,
               each_serializer: UserProjectSerializer,
               include: :user
      end

      def show
        render jsonapi: @user_project,
               serializer: UserProjectSerializer,
               include: :user
      end

      def create
        raise PermissionError.new(Project, :manage) unless can_manage_project?(@project)

        user_project = @project.user_projects.create!(user_project_params.merge!(assigned_by: current_user))

        render jsonapi: user_project, serializer: UserProjectSerializer, status: :created
      end

      def update
        @user_project.role = user_project_params[:role]
        return render body: nil, status: :no_content unless @user_project.changed?

        @user_project.assigned_by = current_user
        @user_project.save!
        render jsonapi: @user_project, serializer: UserProjectSerializer, status: :ok
      end

      def destroy
        @user_project.destroy!
        render body: nil
      end

      private

      def load_user_project
        @user_project = @project.user_projects.find(params.require(:id))
      end

      def load_user_project_for_managing
        @user_project = @project.user_projects.find(params.require(:id))
        raise PermissionError.new(Project, :manage) unless can_manage_project?(@project)
      end

      def user_project_params
        raise TypeError unless params.require(:data).require(:type) == 'user_projects'

        params.require(:data).require(:attributes).permit(:user_id, :role)
      end
    end
  end
end
