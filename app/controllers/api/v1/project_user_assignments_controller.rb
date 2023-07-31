# frozen_string_literal: true

module Api
  module V1
    class ProjectUserAssignmentsController < BaseController
      before_action :load_team
      before_action :load_project
      before_action :check_read_permissions
      before_action :load_user_assignment, only: %i(show update destroy)
      before_action :load_user_project_for_managing, only: %i(show update destroy)

      rescue_from TypeError do
        # TEMP (17.10.2021) additional error details when using the deprecated user_projects
        detail_key = params.dig('data', 'type') == 'user_projects' ? 'user_projects_detail' : 'detail'

        render_error(I18n.t('api.core.errors.type.title'),
                     I18n.t("api.core.errors.type.#{detail_key}"),
                     :bad_request)
      end

      def index
        user_assignments = timestamps_filter(@project.user_assignments).includes(:user_role)
                                                                       .page(params.dig(:page, :number))
                                                                       .per(params.dig(:page, :size))

        render jsonapi: user_assignments,
               each_serializer: UserAssignmentSerializer,
               include: include_params
      end

      def show
        render jsonapi: @user_assignment,
               serializer: UserAssignmentSerializer,
               include: include_params
      end

      def create
        raise PermissionError.new(Project, :manage) unless can_manage_project_users?(@project)

        # internally we reuse the same logic as for user project assignment
        user = @team.users.find(user_project_params[:user_id])

        project_member = ProjectMember.new(user, @project, current_user)
        project_member.assign = true
        project_member.user_role_id = user_project_params[:user_role_id]
        project_member.save
        render jsonapi: project_member.user_assignment.reload,
               serializer: UserAssignmentSerializer,
               status: :created
      end

      def update
        user_role = UserRole.find user_project_params[:user_role_id]
        project_member = ProjectMember.new(@user_assignment.user, @project, current_user)

        return render body: nil, status: :no_content if project_member.user_assignment&.user_role == user_role

        project_member.user_role_id = user_role.id
        project_member.update
        render jsonapi: @user_assignment.reload, serializer: UserAssignmentSerializer, status: :ok
      end

      def destroy
        project_member = ProjectMember.new(@user_assignment.user, @project, current_user)
        project_member.destroy
        render body: nil
      end

      private

      def check_read_permissions
        # team admins can always manage users, so they should also be able to read them
        unless can_read_project_users?(@project) || can_manage_project_users?(@project)
          raise PermissionError.new(Project, :read_users)
        end
      end

      def load_user_assignment
        @user_assignment = @project.user_assignments.find(params.require(:id))
      end

      def load_user_project_for_managing
        raise PermissionError.new(Project, :manage_users) unless can_manage_project_users?(@project)
      end

      def user_project_params
        raise TypeError unless params.require(:data).require(:type) == 'user_assignments'

        params.require(:data).require(:attributes).permit(:user_id, :user_role_id)
      end

      def permitted_includes
        %w(user user_role assignable)
      end
    end
  end
end
