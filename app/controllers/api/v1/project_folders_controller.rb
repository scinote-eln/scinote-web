# frozen_string_literal: true

module Api
  module V1
    class ProjectFoldersController < BaseController
      before_action :load_team
      before_action :load_project_folder, only: %i(show update)

      def index
        project_folders = timestamps_filter(@team.project_folders).page(params.dig(:page, :number))
                                                                  .per(params.dig(:page, :size))

        render jsonapi: project_folders, each_serializer: ProjectFolderSerializer
      end

      def show
        render jsonapi: @project_folder, serializer: ProjectFolderSerializer
      end

      def create
        folder = @team.project_folders.create!(folder_params)

        render jsonapi: folder, serializer: ProjectFolderSerializer, status: :created
      end

      def update
        @project_folder.attributes = update_folder_params

        if @project_folder.changed? && @project_folder.save!
          render jsonapi: @project_folder, serializer: ProjectFolderSerializer
        else
          render jsonapi: nil, status: :no_content
        end
      end

      private

      def load_project_folder
        @project_folder = @team.project_folders.find(params.require(:id))
      end

      def folder_params
        raise TypeError unless params.require(:data).require(:type) == 'project_folders'

        params.permit(data: { attributes: %i(name parent_folder_id) })[:data][:attributes]
      end

      def update_folder_params
        raise IDMismatchError unless params.require(:data).require(:id).to_i == params[:id].to_i

        folder_params
      end
    end
  end
end
