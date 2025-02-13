module Users
  module Settings
    class UserTeamsController < ApplicationController
      include NotificationsHelper
      include InputSanitizeHelper
      include UserRolesHelper

      before_action :load_user_assignment, only: %i(update leave_html destroy_html destroy)
      before_action :check_manage_permissions, except: %i(leave_html destroy_html destroy)
      before_action :check_destroy_permissions, only: %i(leave_html destroy_html destroy)

      def update
        if @user_assignment.update(update_params)
          Activities::CreateActivityService
            .call(activity_type: :change_users_role_on_team,
                  owner: current_user,
                  subject: @user_assignment.assignable,
                  team: @user_assignment.assignable,
                  message_items: {
                    team: @user_assignment.assignable.id,
                    user_changed: @user_assignment.user.id,
                    role: @user_assignment.user_role.name
                  })

          render json: {
            status: :ok
          }
        else
          render json: @user_assignment.errors, status: :unprocessable_entity
        end
      end

      def leave_html
        render json: {
          html: render_to_string(
            partial: 'users/settings/user_teams/leave_user_team_modal_body',
            locals: { user_assignment: @user_assignment },
            formats: :html
          ),
          heading: I18n.t(
            'users.settings.user_teams.leave_uo_heading',
            team: escape_input(@user_assignment.assignable.name)
          )
        }
      end

      def destroy_html
        render json: {
          html: render_to_string(
            partial: 'users/settings/user_teams/' \
                     'destroy_user_team_modal_body',
            locals: { user_assignment: @user_assignment },
            formats: :html
          )
        }
      end

      def destroy
        # If user is last administrator of team,
        # he/she cannot be deleted from it.
        invalid = @user_assignment.last_with_permission?(TeamPermissions::USERS_MANAGE)
        job_id = nil

        unless invalid
          begin
            @user_assignment.transaction do
              if params[:leave]
                Activities::CreateActivityService
                  .call(activity_type: :user_leave_team,
                        owner: current_user,
                        subject: @user_assignment.assignable,
                        team: @user_assignment.assignable,
                        message_items: {
                          team: @user_assignment.assignable.id
                        })
              else
                Activities::CreateActivityService
                  .call(activity_type: :remove_user_from_team,
                        owner: current_user,
                        subject: @user_assignment.assignable,
                        team: @user_assignment.assignable,
                        message_items: {
                          team: @user_assignment.assignable.id,
                          user_removed: @user_assignment.user.id
                        })
              end
              reset_user_current_team(@user_assignment)
              job_id = UserAssignments::RemoveTeamUserAssignmentsJob.perform_later(@user_assignment).job_id
            end
          rescue StandardError => e
            Rails.logger.error e.message
            invalid = true
          end
        end

        if invalid
          render json: @user_assignment.errors, status: :unprocessable_entity
        else
          success_message = if params[:leave]
                              I18n.t(
                                'users.settings.user_teams.leave_flash',
                                team: @user_assignment.assignable.name
                              )
                            else
                              I18n.t(
                                'users.settings.user_teams.remove_flash',
                                user: @user_assignment.user.full_name,
                                team: @user_assignment.assignable.name
                              )
                            end

          generate_notification(current_user,
                                @user_assignment.user,
                                @user_assignment.assignable,
                                false)
          render json: { status: :ok, job_id: job_id, success_message: success_message }
        end
      end

      private

      def load_user_assignment
        @user_assignment = UserAssignment.find_by(id: params[:id])
      end

      def check_manage_permissions
        render_403 unless can_manage_team_users?(@user_assignment.assignable)
      end

      def check_destroy_permissions
        if params[:leave]
          render_403 unless @user_assignment.user == current_user
        else
          render_403 unless can_manage_team_users?(@user_assignment.assignable)
        end
      end

      def update_params
        params.require(:user_assignment).permit(:user_role_id)
      end

      def reset_user_current_team(user_assignment)
        ids = user_assignment.user.teams_ids
        ids -= [user_assignment.assignable.id]
        user_assignment.user.current_team_id = ids.first
        user_assignment.user.save
      end
    end
  end
end
