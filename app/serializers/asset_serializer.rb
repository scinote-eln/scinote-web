class AssetSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :file_name

end
