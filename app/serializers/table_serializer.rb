# frozen_string_literal: true

class TableSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :name, :contents, :urls, :icon, :metadata, :parent_type, :archived, :archived_by, :archived_on

  def contents
    object.contents_utf_8
  end

  def icon
    'sn-icon-tables'
  end

  def parent_type
    :step
  end

  def archived
    object.archived?
  end

  def archived_by
    object.step_table.step_orderable_element.archived_by&.full_name
  end

  def archived_on
    I18n.l(object.step_table.step_orderable_element.archived_on, format: :full) if object.step_table.step_orderable_element.archived_on.present?
  end

  def urls
    return if object.destroyed?

    object.reload unless object.step

    return {} unless can_manage_step?(scope[:user] || @instance_options[:user], object.step)

    step = object.step

    url_list = if object.archived?
                 {
                   restore_url: restore_step_table_path(step, object)
                 }
               else
                 {
                   duplicate_url: duplicate_step_table_path(step, object),
                   update_url: step_table_path(step, object),
                   move_url: move_step_table_path(step, object),
                   move_targets_url: move_targets_step_table_path(step, object)
                 }
               end
    if object.archived? || step.protocol.in_repository?
      url_list[:delete_url] = step_table_path(step, object)
    else
      url_list[:archive_url] = archive_step_table_path(step, object)
    end

    url_list
  end
end
