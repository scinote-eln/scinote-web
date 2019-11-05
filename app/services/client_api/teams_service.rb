module ClientApi
  class TeamsService
    def initialize(arg)
      @params = arg.fetch(:params) { false }
      @user = arg.fetch(:current_user) { raise ClientApi::CustomTeamError }
      team_id = arg.fetch(:team_id) { raise ClientApi::CustomTeamError }
      @team = Team.find_by_id(team_id)
      raise ClientApi::CustomTeamError unless @user.teams.include? @team
    end

    def change_current_team!
      @user.update_attribute(:current_team_id, @team.id)
    end

    def team_page_details_data
      team_users = UserTeam.includes(:user)
                           .references(:user)
                           .where(team: @team)
                           .distinct
      { team: @team, team_users: team_users }
    end

    def single_team_details_data
      { team: @team }
    end

    def update_team!
      raise ClientApi::CustomTeamError unless @params
      return if @team.update(@params)
      raise ClientApi::CustomTeamError, @team.errors.full_messages
    end

    def teams_data
      { teams: @user.datatables_teams }
    end
  end

  CustomTeamError = Class.new(StandardError)
end
