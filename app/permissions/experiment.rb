Canaid::Permissions.register_for(Experiment) do
  can :read_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project) ||
      user.is_admin_of_team?(experiment.project.team) ||
      (experiment.project.visible? &&
        user.is_member_of_team?(experiment.project.team))
  end

  can :manage_experiment do |user, experiment|
    user.is_user_or_higher_of_project?(experiment.project)
  end

  can :restore_experiment do |user, experiment|
    experiment.archived? && can_manage_experiment(user, experiment)
  end
end

Canaid::Permissions.register_for(Protocol) do
  can :read_step_comments do |user, protocol|
    can_read_module_protocol?(user, protocol)
  end

  can :read_protocol do |user, protocol|
    if protocol.in_repository_public?
      user.is_member_of_team(protocol.team)
    elsif protocol.in_repository_private? || protocol.in_repository_archived?
      user.is_member_of_team(protocol.team) and
        protocol.added_by == current_user
    else
      can_read_module_protocol?(user, protocot)
    end
  end
end

private

def can_read_module_protocol?(user, protocol)
  if protocol.in_module?
    my_module = protocol.my_module
    my_module.active? &&
      my_module.experiment.active? &&
      my_module.experiment.project.active? &&
      can_read_experiment?(user, my_module.experiment)
  else
    false
  end
end
