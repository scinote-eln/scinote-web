# frozen_string_literal: true

class TableSerializer < ActiveModel::Serializer
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
    :step
  end

  def urls
    return if object.destroyed?

    object.reload unless object.step

    return {} unless can_manage_step?(scope[:user] || @instance_options[:user], object.step)

    {
      duplicate_url: duplicate_step_table_path(object.step, object),
      delete_url: step_table_path(object.step, object),
      update_url: step_table_path(object.step, object),
      move_targets_url: move_targets_step_table_path(object.step, object),
      move_url: move_step_table_path(object.step, object)
    }
  end
end
