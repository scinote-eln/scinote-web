# frozen_string_literal: true

module RepositoryColumns
  class StockColumnsController < RepositoryColumnsController
    def create
      service = RepositoryColumns::CreateColumnService
                .call(user: current_user, repository: @repository, team: current_team,
                      column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryStockValue],
                      params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :created, creating: true
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def update
      service = RepositoryColumns::UpdateStockColumnService
                .call(user: current_user,
                      team: current_team,
                      column: @repository_column,
                      params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :ok, editing: true
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def items
      column_stock_unit_items = @repository_column.repository_stock_unit_items
                                                  .where('data ILIKE ?', "%#{search_params[:query]}%")
                                                  .select(:id, :data)
                                                  .order(data: :asc)

      render json: column_stock_unit_items.map { |i| { value: i.id, label: escape_input(i.data) } }, status: :ok
    end

    private

    def search_params
      params.permit(:query, :repository_id, :id)
    end

    def repository_column_params
      params
        .require(:repository_column)
        .permit(:name, metadata: [:decimals], repository_stock_unit_items_attributes: %i(data))
    end
  end
end
