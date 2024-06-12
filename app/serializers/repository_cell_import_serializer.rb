# frozen_string_literal: true

class RepositoryCellImportSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :value, :changes, :repository_column_id, :formatted_value

  def changes
    object.value.changes
  end

  def value
    object.value
  end

  def formatted_value
    object.value.formatted
  end
end
