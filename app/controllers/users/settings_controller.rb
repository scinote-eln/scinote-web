module Users
  class SettingsController < ApplicationController
    before_action :load_user, only: [
      :user_current_team
    ]

    def user_current_team
      team_id = params[:user][:current_team_id].to_i
      if @user.teams_ids.include?(team_id)
        @user.current_team_id = team_id
        @changed_team = Team.find_by_id(@user.current_team_id)
        if @user.save
          flash[:success] = t('users.settings.changed_team_flash',
                              team: @changed_team.name)
          redirect_to root_path
          return
        end
      end
      flash[:alert] = t('users.settings.changed_team_error_flash')
      redirect_back(fallback_location: root_path)
    end

    private

    def load_user
      @user = current_user
    end
  end
end
