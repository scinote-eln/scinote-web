# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryNumberValueSerializer < RepositoryBaseValueSerializer
    attributes :full_value

    def value
      decimal_number = scope[:column].metadata.fetch('decimals') { Constants::REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS }
      BigDecimal(object.data).round(decimal_number.to_i)
    end

    def full_value
      object.data
    end
  end
end
