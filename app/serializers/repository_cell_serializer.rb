# frozen_string_literal: true

class RepositoryCellSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attribute :low_stock_threshold, if: -> { object.value_type == 'RepositoryStockValue' }
  attribute :reminder_delta, if: -> { object.value_type == 'RepositoryDateTimeValueBase' }
  attribute :value

  def value
    object.value.data
  end

  def low_stock_threshold
    object.value.low_stock_threshold
  end

  def reminder_delta
    object.repository_column.metadata['reminder_delta']
  end
end
