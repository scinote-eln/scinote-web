# frozen_string_literal: true

module RepositoryColumns
  class TextColumnsController < BaseColumnsController
    include InputSanitizeHelper
    before_action :load_column, only: %i(update destroy)
    before_action :check_create_permissions, only: :create
    before_action :check_manage_permissions, only: %i(update destroy)

    def create
      byebug
      service = RepositoryColumns::CreateColumnService
                .call(user: current_user, repository: @repository, team: current_team,
                      column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue],
                      params: repository_column_params)

      if service.succeed?
        render json: service.column,
               serializer: RepositoryColumnSerializer,
               status: :created
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def update
      byebug

      service = RepositoryColumns::UpdateColumnService
                .call(user: current_user,
                      team: current_team,
                      column: @repository_column,
                      params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :ok
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def destroy
      byebug
      service = RepositoryColumns::DeleteColumnService
                .call(user: current_user, team: current_team, column: @repository_column)

      if service.succeed?
        render json: {}, status: :ok
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    private

    def repository_column_params
      params.require(:repository_column).permit(:name)
    end
  end
end
