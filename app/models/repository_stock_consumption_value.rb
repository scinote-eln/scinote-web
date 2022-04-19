# frozen_string_literal: true

class RepositoryStockConsumptionValue < RepositoryStockValue
  def snapshot!
    # Snapshots should be done from RepositoryStockValue
    railse NotImplementedError
  end
end
