# frozen_string_literal: true

Canaid::Permissions.register_for(Asset) do
  can :read_asset do |user, asset|
    object ||= asset.step
    object ||= asset.result
    object ||= asset.repository_cell

    if object.class == Step
      protocol = object.protocol
      can_read_protocol_in_module?(user, protocol) || can_read_protocol_in_repository?(user, protocol)
    elsif object.class == Result
      can_read_experiment?(user, object.my_module.experiment)
    elsif object.class == RepositoryCell
      can_read_repository?(user, object.repository_column.repository)
    end
  end

  can :manage_asset do |user, asset|
    object ||= asset.step
    object ||= asset.result
    object ||= asset.repository_cell

    if object.class == Step
      protocol = object.protocol
      can_manage_protocol_in_module?(user, protocol) || can_manage_protocol_in_repository?(user, protocol)
    elsif object.class == Result
      can_manage_experiment?(user, object.my_module.experiment)
    elsif object.class == RepositoryCell && !object.repository_column.repository.is_a?(RepositorySnapshot)
      can_manage_repository?(user, object.repository_column.repository)
    end
  end
end
