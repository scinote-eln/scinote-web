# frozen_string_literal: true

Canaid::Permissions.register_for(Asset) do
  can :read_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    case object
    when Step
      protocol = object.protocol
      can_read_protocol_in_module?(user, protocol) || can_read_protocol_in_repository?(user, protocol)
    when ResultBase
      can_read_result?(user, object)
    when RepositoryCell
      can_read_repository?(user, object.repository_column.repository)
    end
  end

  can :manage_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    case object
    when Step
      asset.active? && can_manage_step?(user, object)
    when ResultBase
      asset.active? && can_manage_result?(user, object)
    when RepositoryCell
      if object.repository_column.repository.is_a?(RepositorySnapshot)
        false
      else
        object.repository_row.active? &&
        can_manage_repository_assets?(user, object.repository_column.repository)
      end
    end
  end

  can :restore_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    case object
    when Step
      asset.archived? && can_manage_step?(user, object)
    when ResultBase
      asset.archived? && can_manage_result?(user, object)
    when RepositoryCell
      if object.repository_column.repository.is_a?(RepositorySnapshot)
        false
      else
        object.repository_row.active? && can_manage_repository_assets?(user, object.repository_column.repository)
      end
    end
  end

  can :delete_asset do |user, asset|
    object = asset.step || asset.result || asset.repository_cell

    case object
    when Step
      (asset.archived? || object.protocol.in_repository?) && can_manage_step?(user, object)
    when ResultBase
      (asset.archived? || object.respond_to?(:protocol)) && can_manage_result?(user, object)
    when RepositoryCell
      if object.repository_column.repository.is_a?(RepositorySnapshot)
        false
      else
        object.repository_row.active? && can_manage_repository_assets?(user, object.repository_column.repository)
      end
    end
  end

  can :restore_asset_version do |user, asset|
    VersionedAttachments.enabled? && can_manage_asset?(user, asset)
  end

  can :open_asset_locally do |_user, asset|
    ENV['ASSET_SYNC_URL'].present?
  end
end
