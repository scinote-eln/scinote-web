# frozen_string_literal: true

module RepositoryDatatableHelper
  def serialize_repository_cell_value(cell, team, repository, options = {})
    # case/when is used because it is much faster then .constantize
    serializer_class =
      case cell.repository_column.data_type
      when 'RepositoryTextValue' then RepositoryDatatable::RepositoryTextValueSerializer
      when 'RepositoryNumberValue' then RepositoryDatatable::RepositoryNumberValueSerializer
      when 'RepositoryListValue' then RepositoryDatatable::RepositoryListValueSerializer
      when 'RepositoryChecklistValue' then RepositoryDatatable::RepositoryChecklistValueSerializer
      when 'RepositoryStatusValue' then RepositoryDatatable::RepositoryStatusValueSerializer
      when 'RepositoryTimeValue' then RepositoryDatatable::RepositoryTimeValueSerializer
      when 'RepositoryDateValue' then RepositoryDatatable::RepositoryDateValueSerializer
      when 'RepositoryDateTimeValue' then RepositoryDatatable::RepositoryDateTimeValueSerializer
      when 'RepositoryDateRangeValue' then RepositoryDatatable::RepositoryDateRangeValueSerializer
      when 'RepositoryTimeRangeValue' then RepositoryDatatable::RepositoryTimeRangeValueSerializer
      when 'RepositoryDateTimeRangeValue' then RepositoryDatatable::RepositoryDateTimeRangeValueSerializer
      when 'RepositoryAssetValue' then RepositoryDatatable::RepositoryAssetValueSerializer
      when 'RepositoryStockValue' then RepositoryDatatable::RepositoryStockValueSerializer
      when 'RepositoryStockConsumptionValue' then RepositoryDatatable::RepositoryStockConsumptionValueSerializer
      else
        Extends::REPOSITORY_EXTRA_VALUE_SERIALIZERS[cell.value_type]
      end

    serializer_class.new(
      cell.value,
      scope: {
        team: team,
        user: current_user,
        column: cell.repository_column,
        repository: repository,
        options: options
      }
    ).serializable_hash
  end

  def display_stock_warnings?(repository)
    !repository.is_a?(RepositorySnapshot)
  end
end
