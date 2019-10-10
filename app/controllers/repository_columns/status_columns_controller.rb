# frozen_string_literal: true

module RepositoryColumns
  class StatusColumnsController < ApplicationController
    include InputSanitizeHelper
    before_action :load_repository
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
                      params: repository_column_params)

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

    def load_repository
      @repository = Repository.accessible_by_teams(current_team).find_by(id: params[:repository_id])
      render_404 unless @repository
    end

    def load_column
      @repository_column = @repository.repository_columns.find_by(id: params[:id])
      render_404 unless @repository_column
    end

    def repository_column_params
      params.require(:repository_column).permit(:name, repository_status_items_attributes: %i(status icon))
    end

    def check_create_permissions
      render_403 unless can_create_repository_columns?(@repository)
    end

    def check_manage_permissions
      render_403 unless can_manage_repository_column?(@repository_column)
    end
  end
end
