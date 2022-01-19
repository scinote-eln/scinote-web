# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryStockValueSerializer < RepositoryBaseValueSerializer
    def value
      {
        stock_formatted: object.formatted,
        stock_amount: object.data
      }
    end
  end
end
