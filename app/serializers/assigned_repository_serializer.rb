# frozen_string_literal: true

class AssignedRepositorySerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include MyModulesHelper

  attributes :id, :name

  attribute :assigned_rows_count do
    object['assigned_rows_count']
  end

  attribute :is_snapshot do
    object.is_a?(RepositorySnapshot)
  end

  attribute :has_stock do
    object.has_stock_management?
  end

  attribute :has_stock_consumption do
    object.has_stock_consumption?
  end

  attribute :can_manage_consumption do
    can_update_my_module_stock_consumption?(scope[:user], scope[:my_module])
  end

  attribute :stock_column_name do
    object.repository_stock_column.name if object.has_stock_management?
  end

  attribute :footer_label do
    assigned_repository_simple_view_footer_label(object)
  end

  attribute :name_column_id do
    assigned_repository_simple_view_name_column_id(object)
  end

  attribute :urls do
    {
      full_view: assigned_repository_full_view_table_path(scope[:my_module], object),
      assigned_rows: assigned_repository_simple_view_index_path(scope[:my_module], object)
    }
  end
end
