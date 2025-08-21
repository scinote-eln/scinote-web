# frozen_string_literal: true

module AssignmentsHelper
  private

  def prepare_assigned_users
    users = object.assigned_users_with_roles(current_user.current_team).map do |u|
      {
        avatar: avatar_path(u[:user], :icon_small),
        full_name: "#{u[:user].full_name} (#{u[:role].name})"
      }
    end

    user_groups = object.user_group_assignments.where(team: current_user.current_team).map do |ua|
      {
        avatar: ActionController::Base.helpers.asset_path('icon/group.svg'),
        full_name: ua.user_group_name_with_role
      }
    end

    user_groups + users
  end
end
