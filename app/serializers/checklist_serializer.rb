# frozen_string_literal: true

class ChecklistSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :name, :urls, :icon, :sa_name, :checklist_items

  def icon
    'fa-list-ul'
  end

  def checklist_items
    object.checklist_items.map do |item|
      ChecklistItemSerializer.new(item, scope: { user: scope[:user] || @instance_options[:user] }).as_json
    end
  end

  def sa_name
    @user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.name,
                     simple_format: false,
                     tags: %w(img),
                     team: object.step.protocol.team)
  end

  def urls
    return {} if object.destroyed? || !can_manage_step?(scope[:user] || @instance_options[:user], object.step)

    {
      duplicate_url: duplicate_step_checklist_path(object.step, object),
      delete_url: step_checklist_path(object.step, object),
      update_url: step_checklist_path(object.step, object),
      reorder_url: reorder_step_checklist_checklist_items_path(object.step, object),
      create_item_url: step_checklist_checklist_items_path(object.step, object)
    }
  end
end
