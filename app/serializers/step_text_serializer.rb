# frozen_string_literal: true

class StepTextSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :text, :urls

  def urls
    return unless object.step

    {
      delete_url: step_text_path(object.step, object)
    }
  end
end
