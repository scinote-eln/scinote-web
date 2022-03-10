# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockValueSerializer < RepositoryBaseValueSerializer
    include Canaid::Helpers::PermissionsHelper

    def value
      {
        stock_formatted: object.formatted,
        stock_amount: object.data,
        low_stock_threshold: object.low_stock_threshold
      }
    end
  end
end
