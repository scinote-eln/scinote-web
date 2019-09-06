module ClientApi
  class UserTeamService
    include NotificationsHelper
    include InputSanitizeHelper

    def initialize(args)
      parsed_args = validate_params(args)
      @team = Team.find_by_id(parsed_args.fetch(:team_id))
      @user = parsed_args.fetch(:user)
      @user_team = UserTeam.find_by_id(parsed_args.fetch(:user_team_id).to_i)
      @role = args.fetch(:role) { false }
    end

    def destroy_user_team_and_assign_new_team_owner!
      raise ClientApi::CustomUserTeamError if user_cant_leave?
      new_owner = @team.user_teams
                       .where(role: 2)
                       .where.not(id: @user_team.id)
                       .first.user
      new_owner ||= @user
      reset_user_current_team(@user_team)
      @user_team.destroy(new_owner)
      generate_new_notification
    end

    def update_role!
      raise ClientApi::CustomUserTeamError if user_cant_leave?
      unless @role
        raise ClientApi::CustomUserTeamError,
              I18n.t('client_api.generic_error_message')
      end
      return if @user_team.update_attribute(:role, @role)
      raise ClientApi::CustomUserTeamError, @user_team.errors.full_messages
    end

    def team_users_data
      team_users = UserTeam.includes(:user)
                           .references(:user)
                           .where(team: @team)
                           .distinct
      { team_users: team_users }
    end

    def teams_data
      {
        teams: @user.datatables_teams,
        flash_message: I18n.t('client_api.user_teams.leave_flash',
                              team: @team.name)
      }
    end

    private

    def reset_user_current_team(user_team)
      ids = user_team.user.teams_ids
      ids -= [user_team.team.id]
      user_team.user.current_team_id = ids.first
      user_team.user.save
    end

    def user_cant_leave?
      @user.teams.include?(@team) &&
        @user_team.admin? &&
        @team.user_teams.where(role: 2).count <= 1
    end

    def generate_new_notification
      user = @user_team.user
      generate_notification(user,
                            user,
                            @user_team.team,
                            false)
    end

    def validate_params(args)
      keys = %i(team_id user_team_id user)
      raise ClientApi::CustomUserTeamError unless keys.all? { |s| args.key? s }
      raise ClientApi::CustomUserTeamError if args.values.any? &:nil?
      team_id = args.fetch(:team_id)
      user_team_id = args.fetch(:user_team_id)
      user = args.fetch(:user)
      { user: user, user_team_id: user_team_id, team_id: team_id }
    end
  end
  CustomUserTeamError = Class.new(StandardError)
end
