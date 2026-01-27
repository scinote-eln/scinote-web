# frozen_string_literal: true

class AssignedRepositorySerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include MyModulesHelper

  attributes :id

  attribute :name do
    can_read? ? object.name : I18n.t('my_modules.assigned_items.repository.private_repository_name')
  end

  attribute :assigned_rows_count do
    object['assigned_rows_count']
  end

  attribute :is_snapshot do
    object.is_a?(RepositorySnapshot)
  end

  attribute :permissions do
    {
      can_assign: can_assign_my_module_repository_rows?(scope[:user], scope[:my_module]),
      can_read: can_read?
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
