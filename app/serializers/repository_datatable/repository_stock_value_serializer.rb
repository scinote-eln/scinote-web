# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockValueSerializer < RepositoryBaseValueSerializer
    include Canaid::Helpers::PermissionsHelper

    def value
      {
        stock_formatted: value_object.formatted,
        stock_amount: value_object.data,
        low_stock_threshold: value_object.low_stock_threshold
      }
    end
  end
end
