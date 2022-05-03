# frozen_string_literal: true

class StepTableSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :urls

  def urls
    return unless object.step

    {
      delete_url: step_table_path(object.step, object)
    }
  end
end
