# frozen_string_literal: true

class ChecklistSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :name, :urls, :icon
  has_many :checklist_items, serializer: ChecklistItemSerializer

  def icon
    'fa-list-ul'
  end

  def urls
    return {} if object.destroyed? || !can_manage_step?(scope[:user] || @instance_options[:user], object.step)

    {
      delete_url: step_checklist_path(object.step, object),
      update_url: step_checklist_path(object.step, object),
      reorder_url: reorder_step_checklist_checklist_items_path(object.step, object),
      create_item_url: step_checklist_checklist_items_path(object.step, object)
    }
  end
end
