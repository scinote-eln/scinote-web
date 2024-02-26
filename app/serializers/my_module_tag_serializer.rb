# frozen_string_literal: true

class MyModuleTagSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :tag_id, :urls

  def urls
    {
      update: my_module_my_module_tag_path(object.my_module, object, format: :json)
    }
  end
end
