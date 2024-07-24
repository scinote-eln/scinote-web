# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryNumberValueSerializer < RepositoryBaseValueSerializer
    def value
      decimals = scope[:column].metadata.fetch('decimals', Constants::REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS).to_i
      value_object.data.round(decimals).to_s
    end
  end
end
