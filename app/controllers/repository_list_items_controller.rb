class RepositoryListItemsController < ApplicationController
  before_action :load_vars, only: :search

  def search
    column_list_items = @repository_column.repository_list_items
                                          .where('data ILIKE ?',
                                                 "%#{search_params[:q]}%")
                                          .limit(Constants::SEARCH_LIMIT)
                                          .select(:id, :data)

    render json: { list_items: column_list_items }, status: :ok
  end

  private

  def search_params
    params.permit(:q, :column_id)
  end

  def load_vars
    @repository_column = RepositoryColumn.find_by_id(search_params[:column_id])
    repository = @repository_column.repository if @repository_column
    unless @repository_column&.data_type == 'RepositoryListValue'
      render_404 and return
    end
    render_403 unless can_manage_repository_rows?(repository.team)
  end
end
