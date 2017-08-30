module ClientApi
  class TeamsService
    MissingTeamError = Class.new(StandardError)
    def initialize(arg)
      team_id = arg.fetch(:team_id) { raise MissingTeamError }
      @team = Team.find_by_id(team_id)
      @current_user = arg.fetch(:current_user) { raise MissingTeamError }
      raise MissingTeamError unless @current_user.teams.include? @team
    end

    def change_current_team!
      @current_user.update_attribute(:current_team_id, @team.id)
    end

    def team_page_details_data
      { team: @team, users: @team.users.eager_load(:user_teams) }
    end

    def teams_data
      { teams: @current_user.teams_data }
    end
  end
end
