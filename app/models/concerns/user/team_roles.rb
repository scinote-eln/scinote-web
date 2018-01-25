require 'aspector'

module User::TeamRoles
  extend ActiveSupport::Concern

  aspector do
    # Check if user is member of team
    around %i(
      is_member_of_team?
      is_admin_of_team?
      is_normal_user_of_team?
      is_normal_user_or_admin_of_team?
      is_guest_of_team?
    ) do |proxy, *args, &block|
      if args[0]
        @user_team = user_teams.where(team: args[0]).take
        @user_team ? proxy.call(*args, &block) : false
      else
        false
      end
    end
  end

  def is_member_of_team?(team)
    # This is already checked by aspector, so just return true
    true
  end

  def is_admin_of_team?(team)
    @user_team.admin?
  end

  def is_normal_user_of_team?(team)
    @user_team.normal_user?
  end

  def is_normal_user_or_admin_of_team?(team)
    @user_team.normal_user? or @user_team.admin?
  end

  def is_guest_of_team?(team)
    @user_team.guest?
  end
end