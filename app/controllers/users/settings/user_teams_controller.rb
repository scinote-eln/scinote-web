module Users
  module Settings
    class UserTeamsController < ApplicationController
      before_action :load_user, only: :destroy

      before_action :load_user_team, only: [
        :update,
        :leave_html,
        :destroy_html,
        :destroy
      ]

      def update
        respond_to do |format|
          if @user_team.update(update_user_team_params)
            format.json do
              render json: {
                status: :ok
              }
            end
          else
            format.json do
              render json: @user_team.errors,
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
                  'users/settings/user_teams/leave_user_team_modal_body.html.erb',
                locals: { user_team: @user_team }
              ),
              heading: I18n.t(
                'users.settings.user_teams.leave_uo_heading',
                team: escape_input(@user_team.team.name)
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
                locals: { user_team: @user_team }
              ),
              heading: I18n.t(
                'users.settings.user_teams.destroy_uo_heading',
                user: escape_input(@user_team.user.full_name),
                team: escape_input(@user_team.team.name)
              )
            }
          end
        end
      end

      def destroy
        respond_to do |format|
          # If user is last administrator of team,
          # he/she cannot be deleted from it.
          invalid =
            @user_team.admin? &&
            @user_team
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
                    @user_team
                    .team
                    .user_teams
                    .where(role: 2)
                    .where.not(id: @user_team.id)
                    .first
                    .user
                else
                  # Otherwise, the new owner for projects is
                  # the current user (= an administrator removing
                  # the user from the team)
                  new_owner = current_user
                end
                reset_user_current_team(@user_team)
                @user_team.destroy(new_owner)
              end
            rescue Exception
              invalid = true
            end
          end

          if !invalid
            if params[:leave]
              flash[:notice] = I18n.t(
                'users.settings.user_teams.leave_flash',
                team: @user_team.team.name
              )
              flash.keep(:notice)
            end
            generate_notification(@user_team.user,
                                  @user_team.user,
                                  @user_team.team,
                                  false,
                                  false)
            format.json { render json: { status: :ok } }
          else
            format.json do
              render json: @user_team.errors,
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
        @user_team = UserTeam.find_by_id(params[:id])
        @team = @user_team.team
        # Don't allow the user to modify UserTeam-s if he's not admin,
        # unless he/she is modifying his/her UserTeam
        if current_user != @user_team.user &&
           !is_admin_of_team(@user_team.team)
          render_403
        end
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
