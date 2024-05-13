# frozen_string_literal: true

class RepositoryCellSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :value, :changes

  def changes
    object.value.changes
  end

  def value
    object.value
  end
end
