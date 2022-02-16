# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockConsumptionValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        consumed_stock_formatted: object.formatted,
        consumed_stock: object.data
      }
    end
  end
end
