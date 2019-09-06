module Users
  module Settings
    class UserTeamsController < ApplicationController
      include NotificationsHelper
      include InputSanitizeHelper

      before_action :load_user, only: :destroy

      before_action :load_user_team, only: [
        :update,
        :leave_html,
        :destroy_html,
        :destroy
      ]

      def update
        respond_to do |format|
          if @user_t.update(update_params)
            # If user is administrator of team,
            # and he/she changes his/her role
            # he/she should be redirected to teams page
            new_path = teams_path if @user_t.user == @current_user &&
                                     @user_t.role != 'admin'

            Activities::CreateActivityService
              .call(activity_type: :change_users_role_on_team,
                    owner: current_user,
                    subject: @user_t.team,
                    team: @user_t.team,
                    message_items: {
                      team: @user_t.team.id,
                      user_changed: @user_t.user.id,
                      role: @user_t.role_str
                    })

            format.json do
              render json: {
                status: :ok,
                new_path: new_path
              }
            end
          else
            format.json do
              render json: @user_t.errors,
              status: :unprocessable_entity
            end
          end
        end
      end

      def leave_html
        respond_to do |format|
          format.json do
            render json: {
              html: render_to_string(
                partial:
                  'users/settings/user_teams/' \
                  'leave_user_team_modal_body.html.erb',
                locals: { user_team: @user_t }
              ),
              heading: I18n.t(
                'users.settings.user_teams.leave_uo_heading',
                team: escape_input(@user_t.team.name)
              )
            }
          end
        end
      end

      def destroy_html
        respond_to do |format|
          format.json do
            render json: {
              html: render_to_string(
                partial: 'users/settings/user_teams/' \
                         'destroy_user_team_modal_body.html.erb',
                locals: { user_team: @user_t }
              ),
              heading: I18n.t(
                'users.settings.user_teams.destroy_uo_heading',
                user: escape_input(@user_t.user.full_name),
                team: escape_input(@user_t.team.name)
              )
            }
          end
        end
      end

      def destroy
        # If user is last administrator of team,
        # he/she cannot be deleted from it.
        invalid =
          @user_t.admin? &&
          @user_t
          .team
          .user_teams
          .where(role: 2)
          .count <= 1

        unless invalid
          begin
            UserTeam.transaction do
              # If user leaves on his/her own accord,
              # new owner for projects is the first
              # administrator of team
              if params[:leave]
                new_owner =
                  @user_t
                  .team
                  .user_teams
                  .where(role: 2)
                  .where.not(id: @user_t.id)
                  .first
                  .user
                Activities::CreateActivityService
                  .call(activity_type: :user_leave_team,
                        owner: current_user,
                        subject: @user_t.team,
                        team: @user_t.team,
                        message_items: {
                          team: @user_t.team.id
                        })
              else
                # Otherwise, the new owner for projects is
                # the current user (= an administrator removing
                # the user from the team)
                new_owner = current_user
                Activities::CreateActivityService
                .call(activity_type: :remove_user_from_team,
                      owner: current_user,
                      subject: @user_t.team,
                      team: @user_t.team,
                      message_items: {
                        team: @user_t.team.id,
                        user_removed: @user_t.user.id
                      })
              end
              reset_user_current_team(@user_t)

              @user_t.destroy(new_owner)
            end
          rescue Exception
            invalid = true
          end
        end

        respond_to do |format|
          if !invalid
            if params[:leave]
              flash[:notice] = I18n.t(
                'users.settings.user_teams.leave_flash',
                team: @user_t.team.name
              )
              flash.keep(:notice)
            end
            generate_notification(current_user,
                                  @user_t.user,
                                  @user_t.team,
                                  false)
            format.json { render json: { status: :ok } }
          else
            format.json do
              render json: @user_t.errors,
              status: :unprocessable_entity
            end
          end
        end
      end

      private

      def load_user
        @user = current_user
      end

      def load_user_team
        @user_t = UserTeam.find_by_id(params[:id])
        @team = @user_t.team
        # Don't allow the user to modify UserTeam-s if he's not admin,
        # unless he/she is modifying his/her UserTeam
        if current_user != @user_t.user &&
           !can_manage_team_users?(@user_t.team)
          render_403
        end
      end

      def update_params
        params.require(:user_team).permit(
          :role
        )
      end

      def reset_user_current_team(user_team)
        ids = user_team.user.teams_ids
        ids -= [user_team.team.id]
        user_team.user.current_team_id = ids.first
        user_team.user.save
      end
    end
  end
end
