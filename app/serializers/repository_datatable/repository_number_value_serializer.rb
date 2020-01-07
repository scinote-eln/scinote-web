# frozen_string_literal: true

module RepositoryDatatable
  class RepositoryNumberValueSerializer < RepositoryBaseValueSerializer
    attributes :value_decimals

    def value
      object.data
    end

    def value_decimals
      object.repository_cell
            .repository_column
            .metadata
            .fetch('decimals') { Constants::REPOSITORY_NUMBER_TYPE_DEFAULT_DECIMALS }
    end
  end
end
