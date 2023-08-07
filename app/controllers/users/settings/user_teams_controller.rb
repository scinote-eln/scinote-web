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
          ),
          heading: I18n.t(
            'users.settings.user_teams.destroy_uo_heading',
            user: escape_input(@user_assignment.user.full_name),
            team: escape_input(@user_assignment.assignable.name)
          )
        }
      end

      def destroy
        # If user is last administrator of team,
        # he/she cannot be deleted from it.
        invalid =
          managing_team_user_roles_collection.include?(@user_assignment.user_role) &&
          @user_assignment
          .assignable
          .user_assignments
          .where(user_role: managing_team_user_roles_collection)
          .count <= 1

        unless invalid
          begin
            @user_assignment.transaction do
              # If user leaves on his/her own accord,
              # new owner for projects is the first
              # administrator of team
              if params[:leave]
                new_owner =
                  @user_assignment
                  .assignable
                  .user_assignments
                  .where(user_role: managing_team_user_roles_collection)
                  .where.not(id: @user_assignment.id)
                  .first
                  .user
                Activities::CreateActivityService
                  .call(activity_type: :user_leave_team,
                        owner: current_user,
                        subject: @user_assignment.assignable,
                        team: @user_assignment.assignable,
                        message_items: {
                          team: @user_assignment.assignable.id
                        })
              else
                # Otherwise, the new owner for projects is
                # the current user (= an administrator removing
                # the user from the team)
                new_owner = current_user
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

              remove_user_from_team!(@user_assignment, new_owner)
            end
          rescue StandardError => e
            Rails.logger.error e.message
            invalid = true
          end
        end

        if !invalid
          if params[:leave]
            flash[:notice] = I18n.t(
              'users.settings.user_teams.leave_flash',
              team: @user_assignment.assignable.name
            )
            flash.keep(:notice)
          end
          generate_notification(current_user,
                                @user_assignment.user,
                                @user_assignment.assignable,
                                false)
          render json: { status: :ok }
        else
          render json: @user_assignment.errors, status: :unprocessable_entity
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

      def remove_user_from_team!(user_assignment, new_owner)
        return user_assignment.destroy! unless new_owner

        # Also, make new owner author of all protocols that belong
        # to the departing user and belong to this team.
        p_ids = user_assignment.user.added_protocols.where(team: user_assignment.assignable).pluck(:id)
        Protocol.where(id: p_ids).find_each do |protocol|
          protocol.record_timestamps = false
          protocol.added_by = new_owner
          protocol.archived_by = new_owner if protocol.archived_by == user_assignment.user
          protocol.restored_by = new_owner if protocol.restored_by == user_assignment.user
          protocol.save!(validate: false)
          protocol.user_assignments.find_by(user: new_owner)&.destroy!
          protocol.user_assignments.create!(
            user: new_owner,
            user_role: UserRole.find_predefined_owner_role,
            assigned: :manually
          )
        end

        # Make new owner author of all inventory items that were added
        # by departing user and belong to this team.
        RepositoryRow.change_owner(user_assignment.assignable, user_assignment.user, new_owner)

        user_assignment.destroy!
      end
    end
  end
end
