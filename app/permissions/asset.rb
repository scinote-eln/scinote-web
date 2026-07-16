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
      asset.active? && !asset.locked? && can_manage_step?(user, object)
    when ResultBase
      asset.active? && !asset.locked? && can_manage_result?(user, object)
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
      if object.protocol.in_repository?
        (!asset.locked? || can_manage_protocol_draft_in_repository?(user, object.protocol)) &&
          can_manage_step?(user, object)
      else
        !asset.locked? &&
          asset.archived? &&
          object.team.protocol_steps_deletion_enabled? &&
          can_manage_step?(user, object)
      end
    when ResultBase
      if object.respond_to?(:protocol)
        (!asset.locked? || can_manage_protocol_draft_in_repository?(user, object.protocol)) &&
          can_manage_result?(user, object)
      else
        !asset.locked? &&
          asset.archived? &&
          object.team.result_deletion_enabled? &&
          can_manage_result?(user, object)
      end
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

  can :lock_asset do |user, asset|
    object = asset.step || asset.result
    case object
    when Step
      can_manage_protocol_draft_in_repository?(user, object.protocol)
    when ResultBase
      object.respond_to?(:protocol) && can_manage_protocol_draft_in_repository?(user, object.protocol)
    else
      false
    end
  end

  can :unlock_asset do |user, asset|
    object = asset.step || asset.result
    case object
    when Step
      can_manage_protocol_draft_in_repository?(user, object.protocol)
    when ResultBase
      object.respond_to?(:protocol) && can_manage_protocol_draft_in_repository?(user, object.protocol)
    else
      false
    end
  end

  can :open_asset_locally do |_user, asset|
    ENV['ASSET_SYNC_URL'].present?
  end
end
