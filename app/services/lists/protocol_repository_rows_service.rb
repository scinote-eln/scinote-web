# frozen_string_literal: true

module Lists
  class ProtocolRepositoryRowsService < BaseService
    private

    def fetch_records
      @records = @raw_data.left_joins(repository_row: :repository)
    end

    def filter_records
      return if @params[:search].blank?

      @records = @records.where_attributes_like(
        ['repositories.name', 'repository_rows.name', RepositoryRow::PREFIXED_ID_SQL],
        @params[:search]
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'repository_rows.name',
        row_code: 'repository_rows.id',
        repository_name: 'repositories.name'
      }
    end
  end
end
