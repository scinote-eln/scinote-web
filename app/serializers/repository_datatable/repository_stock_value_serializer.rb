# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockValueSerializer < RepositoryBaseValueSerializer
    include Canaid::Helpers::PermissionsHelper

    def value
      data = {
        stock_formatted: value_object.formatted,
        stock_amount: value_object.data,
        low_stock_threshold: value_object.low_stock_threshold
      }
      if scope.dig(:options, :reminders_enabled) &&
         !scope[:repository].is_a?(RepositorySnapshot) &&
         value_object.data.present? &&
         value_object.low_stock_threshold.present?
        data[:reminder] = value_object.low_stock_threshold > value_object.data
      end
      data
    end
  end
end
