# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockConsumptionValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        consumed_stock_formatted: value_object.formatted,
        consumed_stock: value_object.data
      }
    end
  end
end
