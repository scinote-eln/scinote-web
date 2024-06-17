# frozen_string_literal: true

class RepositoryCellSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :value, :repository_column_id, :formatted_value

  def value
    object.value
  end

  def formatted_value
    object.value.formatted
  end
end
