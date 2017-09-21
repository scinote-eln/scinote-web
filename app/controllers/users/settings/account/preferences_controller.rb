module Users
  module Settings
    module Account
      class PreferencesController < ApplicationController
        before_action :load_user, only: [
          :index,
          :update,
          :tutorial,
          :reset_tutorial,
          :notifications_settings
        ]

        def index
        end

        def update
          respond_to do |format|
            if @user.update(update_params)
              flash[:notice] =
                t('users.settings.account.preferences.update_flash')
              format.json do
                flash.keep
                render json: { status: :ok }
              end
            else
              format.json do
                render json: @user.errors,
                status: :unprocessable_entity
              end
            end
          end
        end

        def tutorial
          @teams =
            @user
            .user_teams
            .includes(team: :users)
            .where(role: 1..2)
            .order(created_at: :asc)
            .map(&:team)
          @member_of = @teams.count

          respond_to do |format|
            format.json do
              render json: {
                status: :ok,
                html: render_to_string(
                  partial: 'users/settings/account/preferences/' \
                           'repeat_tutorial_modal_body.html.erb'
                )
              }
            end
          end
        end

        def reset_tutorial
          if @user.update(tutorial_status: 0) && params[:team][:id].present?
            @user.update(current_team_id: params[:team][:id])
            cookies.delete :tutorial_data
            cookies.delete :current_tutorial_step
            cookies[:repeat_tutorial_team_id] = {
              value: params[:team][:id],
              expires: 1.day.from_now
            }

            flash[:notice] = t(
              'users.settings.account.preferences.tutorial.tutorial_reset_flash'
            )
            redirect_to root_path
          else
            flash[:alert] = t(
              'users.settings.account.preferences.tutorial.tutorial_reset_error'
            )
            redirect_to :back
          end
        end

        def notifications_settings
          @user.settings[:notifications][:assignments] =
            params[:assignments_notification] ? true : false
          @user.settings[:notifications][:recent] =
            params[:recent_notification] ? true : false
          @user.settings[:notifications][:recent_email] =
            params[:recent_notification_email] ? true : false
          @user.settings[:notifications][:assignments_email] =
            params[:assignments_notification_email] ? true : false
          @user.settings[:notifications][:system_message_email] =
            params[:system_message_notification_email] ? true : false

          if @user.save
            respond_to do |format|
              format.json do
                render json: {
                  status: :ok
                }
              end
            end
          else
            respond_to do |format|
              format.json do
                render json: {
                  status: :unprocessable_entity
                }
              end
            end
          end
        end

        private

        def load_user
          @user = current_user
        end

        def update_params
          params.require(:user).permit(
            :time_zone
          )
        end
      end
    end
  end
end
