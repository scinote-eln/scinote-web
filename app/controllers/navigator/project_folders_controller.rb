# frozen_string_literal: true

module Navigator
  class ProjectFoldersController < BaseController
    before_action :load_project_folder

    def show
      folder = project_level_branch(@project_folder)
      render json: { items: folder }
    end

    def tree
      tree = project_level_branch(@project_folder)
      tree = build_folder_tree(@project_folder, tree)
      render json: { items: tree }
    end

    private

    def load_project_folder
      @project_folder = current_team.project_folders.find_by(id: params[:id])
    end
  end
end
