# frozen_string_literal: true

class TableSerializer < ActiveModel::Serializer
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
    :step
  end

  def urls
    return if object.destroyed?
    return {} unless managable?

    step = @instance_options[:step] || object.step_table.step_orderable_element.step
    {
      duplicate_url: duplicate_step_table_path(step, object),
      delete_url: step_table_path(step, object),
      update_url: step_table_path(step, object),
      move_targets_url: move_targets_step_table_path(step, object),
      move_url: move_step_table_path(step, object)
    }
  end

  def managable?
    return @instance_options[:managable_step] unless @instance_options[:managable_step].nil?

    step = @instance_options[:step] || object.step_table.step_orderable_element.step
    can_manage_step?(scope[:user] || @instance_options[:user], step)
  end
end
