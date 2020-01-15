# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryNumberValueSerializer < RepositoryBaseValueSerializer
    def value
      decimal_number = scope[:column].metadata.fetch('decimals') { Constants::REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS }
      BigDecimal(object.data).round(decimal_number.to_i)
    end
  end
end
