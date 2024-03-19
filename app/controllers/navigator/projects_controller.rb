# frozen_string_literal: true

module Navigator
  class ProjectsController < BaseController
    before_action :load_project, except: :index
    before_action :check_read_permissions, except: :index

    def index
      project_and_folders = project_level_branch(nil)
      render json: { items: project_and_folders }
    end

    def show
      experiments = experiment_level_branch(@project)
      render json: { items: experiments }
    end

    def tree
      tree = project_level_branch(@project)

      tree = build_folder_tree(@project.project_folder, tree) if @project.project_folder

      render json: { items: tree }
    end

    private

    def load_project
      @project = current_team.projects.find_by(id: params[:id])

      render_404 unless @project
    end

    def check_read_permissions
      render_403 and return unless can_read_project?(@project)
    end
  end
end
