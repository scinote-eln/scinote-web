module PermissionHelpers
  def create_user_assignment(object, role, user, assigned_by = nil)
    user_assignment = UserAssignment.find_by(assignable: object, user: user, user_role: role)

    if user_assignment.blank?
      user_assignment = create :user_assignment,
                               assignable: object,
                               user: user,
                               user_role: role,
                               assigned_by: assigned_by || user
    end

    case object
    when MyModule
      create_user_assignment(object.experiment, role, user, assigned_by)
    when Experiment
      create_user_assignment(object.project, role, user, assigned_by)
    end

    user_assignment
  end

  def create_user_group_assignment(object, role, user_group, assigned_by = nil)
    user_group_assignment = UserGroupAssignment.find_by(assignable: object, user_group: user_group, user_role: role)

    if user_group_assignment.blank?
      user_group_assignment = create :user_group_assignment,
                                     assignable: object,
                                     user_group: user_group,
                                     user_role: role,
                                     assigned_by: assigned_by
    end

    case object
    when MyModule
      create_user_group_assignment(object.experiment, role, user_group, assigned_by)
    when Experiment
      create_user_group_assignment(object.project, role, user_group, assigned_by)
    end

    user_group_assignment
  end

  def create_team_assignment(object, role, team, assigned_by = nil)
    team_assignment = TeamAssignment.find_by(assignable: object, team: team, user_role: role)

    if team_assignment.blank?
      team_assignment = create :team_assignment,
                               assignable: object,
                               team: team,
                               user_role: role,
                               assigned_by: assigned_by
    end

    case object
    when MyModule
      create_team_assignment(object.experiment, role, team, assigned_by)
    when Experiment
      create_team_assignment(object.project, role, team, assigned_by)
    end

    team_assignment
  end
end
