# frozen_string_literal: true

Canaid::Permissions.register_for(Asset) do
  can :read_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    case object
    when Step
      protocol = object.protocol
      can_read_protocol_in_module?(user, protocol) || can_read_protocol_in_repository?(user, protocol)
    when Result
<<<<<<< HEAD
      can_read_result?(object)
=======
      can_read_experiment?(user, object.my_module.experiment)
>>>>>>> Pulled latest release
    when RepositoryCell
      can_read_repository?(user, object.repository_column.repository)
    end
  end

  can :manage_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    case object
    when Step
<<<<<<< HEAD
      can_manage_step?(user, object)
    when Result
      can_manage_result?(object)
    when RepositoryCell
      if object.repository_column.repository.is_a?(RepositorySnapshot)
        false
      else
        can_manage_repository?(user, object.repository_column.repository)
      end
=======
      protocol = object.protocol
      can_manage_protocol_in_module?(user, protocol) || can_manage_protocol_in_repository?(user, protocol)
    when Result
      can_manage_module?(user, object.my_module)
    when RepositoryCell
      return false if object.repository_column.repository.is_a?(RepositorySnapshot)

      can_manage_repository?(user, object.repository_column.repository)
>>>>>>> Pulled latest release
    end
  end
end
