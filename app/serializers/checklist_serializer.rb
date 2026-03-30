# frozen_string_literal: true

class ChecklistSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :name, :urls, :icon, :sa_name, :parent_type, :archived, :archived_by, :archived_on

  has_many :checklist_items, serializer: ChecklistItemSerializer

  def archived
    object.archived?
  end

  def archived_by
    object.step_orderable_element.archived_by&.full_name
  end

  def archived_on
    I18n.l(object.step_orderable_element.archived_on, format: :full) if object.step_orderable_element.archived_on.present?
  end

  def icon
    'sn-icon-checkllist'
  end

  def parent_type
    :step
  end

  def sa_name
    @user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.name,
                     simple_format: false,
                     tags: %w(img),
                     team: object.step.protocol.team)
  end

  def urls
    if object.destroyed? || !can_manage_step?(scope[:user] || @instance_options[:user], object.step)
      return { checklist_items_url: step_checklist_checklist_items_path(object.step, object) }
    end

    step = object.step

    url_list = if object.archived?
                 {
                   restore_url: restore_step_checklist_path(step, object),
                   checklist_items_url: step_checklist_checklist_items_path(step, object)
                 }
               else
                 {
                   checklist_items_url: step_checklist_checklist_items_path(step, object),
                   duplicate_url: duplicate_step_checklist_path(step, object),
                   update_url: step_checklist_path(step, object),
                   reorder_url: reorder_step_checklist_checklist_items_path(step, object),
                   create_item_url: step_checklist_checklist_items_path(step, object),
                   move_targets_url: move_targets_step_checklist_path(step, object),
                   move_url: move_step_checklist_path(step, object)
                 }
               end
    if object.archived? || step.protocol.in_repository?
      url_list[:delete_url] = step_checklist_path(step, object)
    else
      url_list[:archive_url] = archive_step_checklist_path(step, object)
    end

    url_list
  end
end
