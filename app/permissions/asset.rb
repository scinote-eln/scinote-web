# frozen_string_literal: true

Canaid::Permissions.register_for(Asset) do
  can :read_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    case object
    when Step
      protocol = object.protocol
      can_read_protocol_in_module?(user, protocol) || can_read_protocol_in_repository?(user, protocol)
    when Result
      can_read_result?(object)
    when RepositoryCell
      can_read_repository?(user, object.repository_column.repository)
    end
  end

  can :manage_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    has_permission = case object
    when Step
      can_manage_step?(user, object)
    when Result
      can_manage_result?(user, object)
    when RepositoryCell
      if object.repository_column.repository.is_a?(RepositorySnapshot)
        false
      else
        can_manage_repository_assets?(user, object.repository_column.repository)
      end
    end

    if asset.blob&.metadata&.dig('asset_type') == 'gene_sequence'
      has_permission && !asset.my_module_locked?
    else
      has_permission
    end
  end
end
