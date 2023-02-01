# frozen_string_literal: true

module RepositoryColumns
  class DateTimeColumnsController < RepositoryColumnsController
    include InputSanitizeHelper

    def create
      service = RepositoryColumns::CreateColumnService
                .call(user: current_user, repository: @repository, team: current_team,
                      column_type: column_type_param,
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
                      params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :ok, editing: true
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    private

    def repository_column_params
      params.require(:repository_column).permit(:name, :reminder_value, :reminder_unit, :reminder_message)
    end

    def column_type_param
      params.require(:repository_column).require(:column_type)
    end
  end
end
