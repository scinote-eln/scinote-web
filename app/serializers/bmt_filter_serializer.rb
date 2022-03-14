# frozen_string_literal: true

class BmtFilterSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :filters, :delete_url

  def delete_url
    bmt_filter_path(object.id)
  end
end
