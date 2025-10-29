# frozen_string_literal: true

class ResultTableSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :name, :contents, :urls, :icon, :metadata, :parent_type

  def contents
    object.contents_utf_8
  end

  def icon
    'sn-icon-tables'
  end

  def parent_type
    :result
  end

  def urls
    return if object.destroyed?

    object.reload unless object.result
    user = scope[:user] || @instance_options[:user]

    return {} unless can_manage_result?(user, object.result)

    result = object.result

    {
      duplicate_url: duplicate_result_table_path(result, object),
      delete_url: result_table_path(result, object),
      update_url: result_table_path(result, object),
      move_targets_url: move_targets_result_table_path(result, object),
      move_url: move_result_table_path(result, object)
    }
  end
end
