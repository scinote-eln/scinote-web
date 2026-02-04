# frozen_string_literal: true

class AssignedRepositorySerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include MyModulesHelper

  attributes :id, :parent_id

  attribute :name do
    can_read? ? object.name : I18n.t('my_modules.assigned_items.repository.private_repository_name')
  end

  attribute :assigned_rows_count do
    object['assigned_rows_count'] || scope[:assigned_rows_count]
  end

  attribute :has_live_version do
    scope[:my_module].my_module_repository_rows.count.positive?
  end

  attribute :is_snapshot do
    object.is_a?(RepositorySnapshot)
  end

  attribute :permissions do
    {
      can_assign: can_assign_my_module_repository_rows?(scope[:user], scope[:my_module]),
      can_read: can_read?,
      can_create_snapshots: can_create_my_module_repository_snapshots?(scope[:user], scope[:my_module]),
      can_manage_snapshots: can_manage_my_module_repository_snapshots?(scope[:user], scope[:my_module])
    }
  end

  def can_read?
    @can_read ||= can_read_repository?(scope[:user], object)
  end

  attribute :urls do
    {
      export: export_repository_my_module_repository_path(scope[:my_module], object)
    }
  end
end
