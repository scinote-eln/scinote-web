# frozen_string_literal: true

module RepositoryColumns
  class ListColumnsController < BaseColumnsController
    before_action :load_column, only: %i(update destroy)
    before_action :check_create_permissions, only: :create
    before_action :check_manage_permissions, only: %i(update destroy)
    helper_method :delimiters

    def create
      service = RepositoryColumns::CreateColumnService
                .call(user: current_user, repository: @repository, team: current_team,
                      column_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue],
                      params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :created
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    def update
      service = RepositoryColumns::UpdateListColumnService
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
      params.require(:repository_column).permit(:name, :delimiter, repository_list_items_attributes: %i(data))
    end

    def delimiters
      Constants::REPOSITORY_LIST_ITEMS_DELIMITERS
        .split(',')
        .map { |e| Hash[t('libraries.manange_modal_column.list_type.delimiters.' + e), e] }
        .inject(:merge)
    end
  end
end
