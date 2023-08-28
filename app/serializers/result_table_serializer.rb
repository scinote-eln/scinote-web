# frozen_string_literal: true

class ResultTableSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :name, :contents, :urls, :icon, :metadata, :parent_type

  def contents
    object.contents_utf_8
  end

  def icon
    'fa-table'
  end

  def parent_type
    :result
  end

  def urls
    return if object.destroyed?

    object.reload unless object.result

    return {} unless can_manage_result?(scope[:user] || @instance_options[:user], object.result)

    {
      duplicate_url: duplicate_my_module_result_table_path(object.result.my_module, object.result, object),
      delete_url: my_module_result_table_path(object.result.my_module, object.result, object),
      update_url: my_module_result_table_path(object.result.my_module, object.result, object),
      move_targets_url: move_targets_my_module_result_table_path(object.result.my_module, object.result, object),
      move_url: move_my_module_result_table_path(object.result.my_module, object.result, object)
    }
  end
end
