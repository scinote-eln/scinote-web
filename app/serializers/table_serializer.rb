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

  def archived_by
    object.archived_by&.full_name
  end

  def archived_on
    I18n.l(object.archived_on, format: :full) if object.archived_on.present?
  end

  def urls
    return if object.destroyed?

    object.reload unless object.step

    step = object.step
    user = scope[:user] || @instance_options[:user]

    url_list = {}

    if can_manage_step_table?(user, object)
      url_list.merge!({
                        duplicate_url: duplicate_step_table_path(step, object),
                        update_url: step_table_path(step, object),
                        move_url: move_step_table_path(step, object),
                        move_targets_url: move_targets_step_table_path(step, object)
                      })
    end

    url_list[:archive_url] = archive_step_table_path(step, object) if can_archive_step_table?(user, object)
    url_list[:restore_url] = restore_step_table_path(step, object) if can_restore_step_table?(user, object)
    url_list[:delete_url] = step_table_path(step, object) if can_delete_step_table?(user, object)

    url_list
  end
end
