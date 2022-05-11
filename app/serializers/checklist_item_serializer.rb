# frozen_string_literal: true

class ChecklistItemSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :text, :checked, :position, :urls

  def urls
    return {} if object.destroyed? || !object.persisted?

    {
      update_url: step_checklist_checklist_item_path(object.checklist.step, object.checklist, object),
      delete_url: step_checklist_checklist_item_path(object.checklist.step, object.checklist, object)
    }
  end
end
