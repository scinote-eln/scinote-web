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

        # internally we reuse the same logic as for user project assignment
        user_role = UserRole.find_by_name user_project_params[:role]
        user = @team.users.find(user_project_params[:user_id])

        project_member = ProjectMember.new(user, @project, current_user)
        project_member.assign = true
        project_member.user_role_id = user_role.id
        project_member.create

        render jsonapi: project_member.user_project, serializer: UserProjectSerializer, status: :created
      end

      def update
        user_role = UserRole.find_by_name user_project_params[:role]
        project_member = ProjectMember.new(@user_project.user, @project, current_user)

        if project_member.user_assignment&.user_role == user_role
          return render body: nil, status: :no_content
        end

        project_member.user_role_id = user_role.id
        project_member.update
        render jsonapi: @user_project, serializer: UserProjectSerializer, status: :ok
      end

      def destroy
        project_member = ProjectMember.new(@user_project.user, @project, current_user)
        project_member.destroy
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
