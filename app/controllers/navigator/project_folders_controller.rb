# frozen_string_literal: true

module Navigator
  class ProjectFoldersController < BaseController
    before_action :load_project_folder

    def show
      folder = project_level_branch(@project_folder, params[:archived] == 'true')
      render json: { items: folder }
    end

    def tree
      project_and_folders = project_level_branch(@project_folder, params[:archived] == 'true')
      if @project_folder.parent_folder
        tree = build_folder_tree(@project_folder, project_and_folders, params[:archived] == 'true')
      end
      render json: { items: tree }
    end

    private

    def load_project_folder
      @project_folder = current_team.project_folders.find_by(id: params[:id])
    end
  end
end
