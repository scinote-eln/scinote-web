# frozen_string_literal: true

module Lists
  class StorageLocationRepositoryRowsService < BaseService
    def initialize(team, params)
      @team = team
      @storage_location_id = params[:storage_location_id]
      @params = params
    end

    def fetch_records
      @records = StorageLocationRepositoryRow.includes(:repository_row).where(storage_location_id: @storage_location_id)
    end

    def filter_records
      if @params[:search].present?
        @records = @records.joins(:repository_row)
                           .where_attributes_like(
                             ['repository_rows.name', RepositoryRow::PREFIXED_ID_SQL],
                             @params[:search]
                           )
      end
    end

    def sort_records
      return unless @params[:order]

      sort = "#{order_params[:column]}_#{sort_direction(order_params)}"

      case sort
      when 'position_formatted_ASC'
        @records = @records.order(Arel.sql("metadata -> 'position' -> 0 ASC, metadata -> 'position' -> 1 ASC"))
      when 'position_formatted_DESC'
        @records = @records.order(Arel.sql("metadata -> 'position' -> 0 DESC, metadata -> 'position' -> 1 DESC"))
      when 'row_id_ASC'
        @records = @records.order(repository_row_id: :asc)
      when 'row_id_DESC'
        @records = @records.order(repository_row_id: :desc)
      when 'row_name_ASC'
        @records = @records.joins(:repository_row).order('repository_rows.name ASC')
      when 'row_name_DESC'
        @records = @records.joins(:repository_row).order('repository_rows.name DESC')
      end
    end
  end
end
