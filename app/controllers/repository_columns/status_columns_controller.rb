# frozen_string_literal: true

module RepositoryColumns
  class StatusColumnsController < RepositoryColumnsController
    include InputSanitizeHelper

    def create
      service = RepositoryColumns::CreateColumnService
                .call(user: current_user, repository: @repository, team: current_team,
                      column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryStatusValue],
                      params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :created, creating: true
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def update
      service = RepositoryColumns::UpdateColumnService
                .call(user: current_user,
                      team: current_team,
                      column: @repository_column,
                      params: update_repository_column_params)

      if service.succeed?
        render json: service.column, status: :ok, editing: true
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def items
      column_status_items = @repository_column.repository_status_items
                                              .where('status ILIKE ?',
                                                     "%#{search_params[:query]}%")
                                              .select(:id, :icon, :status)

      render json: column_status_items
        .map { |i| { value: i.id, label: "#{i.icon} #{escape_input(i.status)}" } }, status: :ok
    end

    private

    def search_params
      params.permit(:query, :repository_id, :id)
    end

    def repository_column_params
      params.require(:repository_column).permit(:name, repository_status_items_attributes: %i(status icon))
    end

    def update_repository_column_params
      params.require(:repository_column).permit(:name, repository_status_items_attributes: %i(id status icon _destroy))
    end
  end
end
