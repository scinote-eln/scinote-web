# frozen_string_literal: true

class ChecklistSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :name, :urls, :icon, :sa_name, :parent_type

  has_many :checklist_items, serializer: ChecklistItemSerializer

  def icon
    'sn-icon-checkllist'
  end

  def parent_type
    :step
  end

  def sa_name
    user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.name,
                     simple_format: false,
                     tags: %w(img),
                     team: user.current_team)
  end

  def urls
    return { checklist_items_url: step_checklist_checklist_items_path(object.step, object) } if object.destroyed? || !managable?

    step = @instance_options[:step] || object.step_orderable_element.step
    {
      checklist_items_url: step_checklist_checklist_items_path(step, object),
      duplicate_url: duplicate_step_checklist_path(step, object),
      delete_url: step_checklist_path(step, object),
      update_url: step_checklist_path(step, object),
      reorder_url: reorder_step_checklist_checklist_items_path(step, object),
      create_item_url: step_checklist_checklist_items_path(step, object),
      move_targets_url: move_targets_step_checklist_path(step, object),
      move_url: move_step_checklist_path(step, object)
    }
  end

  def managable?
    return @instance_options[:managable_step] unless @instance_options[:managable_step].nil?

    step = @instance_options[:step] || object.step_orderable_element.step
    can_manage_step?(scope[:user] || @instance_options[:user], step)
  end
end
