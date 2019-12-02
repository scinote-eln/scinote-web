# frozen_string_literal: true

class RepositoryStatusItemsController < ApplicationController
  before_action :load_vars, only: :search

  def search
    status_items = @repository_column.repository_status_items
                                     .where('status ILIKE ?', "%#{search_params[:q]}%")
                                     .limit(Constants::SEARCH_LIMIT)
                                     .select(:id, :icon, :status)

    render json: { status_items: status_items }, status: :ok
  end

  private

  def search_params
    params.permit(:q, :column_id)
  end

  def load_vars
    @repository_column = RepositoryColumn.find_by(id: search_params[:column_id])
    repository = @repository_column.repository if @repository_column
    render_404 and return unless @repository_column&.data_type == 'RepositoryStatusValue'
    render_403 unless can_manage_repository_rows?(repository)
  end
end
