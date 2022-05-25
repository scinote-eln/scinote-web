# frozen_string_literal: true

class ChecklistSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :urls
  has_many :checklist_items, serializer: ChecklistItemSerializer

  def urls
    return {} if object.destroyed?

    {
      delete_url: step_checklist_path(object.step, object),
      update_url: step_checklist_path(object.step, object),
      reorder_url: reorder_step_checklist_checklist_items_path(object.step, object),
      create_item_url: step_checklist_checklist_items_path(object.step, object)
    }
  end
end
