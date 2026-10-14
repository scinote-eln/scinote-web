# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryNumberValueSerializer < RepositoryBaseValueSerializer
    include ActionView::Helpers::NumberHelper

    def value
      decimals = scope[:column].metadata.fetch('decimals', Constants::REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS).to_i

      number_with_precision(value_object.data, precision: decimals, strip_insignificant_zeros: false)
    end
  end
end
