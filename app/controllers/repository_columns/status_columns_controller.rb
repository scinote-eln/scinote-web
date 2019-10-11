# frozen_string_literal: true

module RepositoryColumns
  class StatusColumnsController < BaseColumnsController
    include InputSanitizeHelper
    before_action :load_column, only: %i(update destroy)
    before_action :check_create_permissions, only: :create
    before_action :check_manage_permissions, only: %i(update destroy)

    # modal popup
    # def new
    #   @repository_column = RepositoryColumn.new
    #   respond_to do |format|
    #     format.json do
    #       render json: {
    #         html: render_to_string(
    #           partial: 'repository_columns/manage_column_modal.html.erb'
    #         )
    #       }
    #     end
    #   end
    # end

    def create
      service = RepositoryColumns::CreateStatusColumnService
                .call(user: current_user, repository: @repository, team: current_team, params: repository_column_params)

      if service.succeed?
        render json: service.column, status: :created
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    # modal popup
    # def edit
    #   respond_to do |format|
    #     format.json do
    #       render json: {
    #         html: render_to_string(
    #           partial: 'repository_columns/manage_column_modal.html.erb'
    #         )
    #       }
    #     end
    #   end
    # end

    def update
      service = RepositoryColumns::UpdateStatusColumnService
                .call(user: current_user,
                      team: current_team,
                      column: @repository_column,
                      params: update_repository_column_params)

      if service.succeed?
        render json: service.column, status: :ok
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    # def destroy_html
    #   respond_to do |format|
    #     format.json do
    #       render json: {
    #         html: render_to_string(
    #           partial: 'repository_columns/delete_column_modal_body.html.erb'
    #         )
    #       }
    #     end
    #   end
    # end

    def destroy
      service = RepositoryColumns::DeleteStatusColumnService
                .call(user: current_user, team: current_team, column: @repository_column)

      if service.succeed?
        render json: {}, status: :ok
      else
        render json: service.errors, status: :unprocessable_entity
      end
    end

    private

    def repository_column_params
      params.require(:repository_column).permit(:name, repository_status_items_attributes: %i(status icon))
    end

    def update_repository_column_params
      params.require(:repository_column).permit(repository_status_items_attributes: %i(id status icon _destroy))
    end
  end
end
