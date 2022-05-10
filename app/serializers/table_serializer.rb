# frozen_string_literal: true

class TableSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :contents, :urls

  def contents
    object.contents_utf_8
  end

  def urls
    return if object.destroyed?

    object.reload unless object.step

    {
      delete_url: step_table_path(object.step, object),
      update_url: step_table_path(object.step, object)
    }
  end
end
