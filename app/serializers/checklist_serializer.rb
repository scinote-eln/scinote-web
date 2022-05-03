# frozen_string_literal: true

class ChecklistSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :urls

  def urls
    return unless object.step

    {
      delete_url: step_checklist_path(object.step, object)
    }
  end
end
