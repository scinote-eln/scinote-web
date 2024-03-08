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

        ActiveRecord::Base.transaction do
          user_assignment = UserAssignment.find_or_initialize_by(
            assignable: @project,
            user_id: user_project_params[:user_id],
            team: @project.team
          )

          user_assignment.update!(
            user_role_id: user_project_params[:user_role_id],
            assigned_by: current_user,
            assigned: :manually
          )

          log_activity(:assign_user_to_project, { user_target: user_assignment.user.id,
                                                  role: user_assignment.user_role.name })
          propagate_job(user_assignment)

          render jsonapi: user_assignment.reload,
                 serializer: UserAssignmentSerializer,
                 status: :created
        end
      end

      def update
        # prevent role change if it would result in no manually assigned users having the user management permission
        new_user_role = UserRole.find(user_project_params[:user_role_id])
        if !new_user_role.has_permission?(ProjectPermissions::USERS_MANAGE) &&
           @user_assignment.last_with_permission?(ProjectPermissions::USERS_MANAGE, assigned: :manually)
          raise ActiveRecord::RecordInvalid
        end

        return render body: nil, status: :no_content if @user_assignment&.user_role == new_user_role

        ActiveRecord::Base.transaction do
          @user_assignment.update!(user_role: new_user_role)

          log_activity(:change_user_role_on_project, { user_target: @user_assignment.user.id,
                                                       role: @user_assignment.user_role.name })

          propagate_job(@user_assignment)
        end

        render jsonapi: @user_assignment.reload, serializer: UserAssignmentSerializer, status: :ok
      end

      def destroy
        # prevent deletion of last manually assigned user that can manage users
        if @user_assignment.last_with_permission?(ProjectPermissions::USERS_MANAGE, assigned: :manually)
          raise ActiveRecord::RecordInvalid
        end

        ActiveRecord::Base.transaction do
          if @project.visible?
            @user_assignment.update!(
              user_role: @project.default_public_user_role,
              assigned: :automatically
            )
          else
            @user_assignment.destroy!
          end

          propagate_job(@user_assignment, destroy: true)
          log_activity(:unassign_user_from_project, { user_target: @user_assignment.user.id,
                                                      role: @user_assignment.user_role.name })
        end

        render body: nil
      end

      private

      def propagate_job(user_assignment, destroy: false)
        UserAssignments::PropagateAssignmentJob.perform_later(
          @project,
          user_assignment.user.id,
          user_assignment.user_role,
          current_user.id,
          destroy: destroy
        )
      end

      def log_activity(type_of, message_items = {})
        message_items = { project: @project.id }.merge(message_items)

        Activities::CreateActivityService
          .call(activity_type: type_of,
                owner: current_user,
                subject: @project,
                team: @project.team,
                project: @project,
                message_items: message_items)
      end

      # Override, in order to handle special case for team owners
      def load_project
        @project = @team.projects.find(params.require(:project_id))
      end

      def check_read_permissions
        raise PermissionError.new(Project, :read_users) unless can_read_project_users?(@project)
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
