# frozen_string_literal: true

class ProjectFoldersController < ApplicationController
  before_action :load_current_folder, only: %i(new)
  before_action :check_create_permissions, only: %i(new create)

  def new
    @project_folder = ProjectFolder.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'projects/index/modals/new_project_folder.html.erb'
          )
        }
      end
    end
  end

  def create
    @project_folder = ProjectFolder.new(team: current_team)
    @project_folder.assign_attributes(project_folders_params)

    respond_to do |format|
      format.json do
        if @project_folder.save
          # log_activity()
          flash[:success] = t('projects.index.modal_new_project_folder.success_flash',
                              name: @project_folder.name)
          render json: { url: project_folder_path(@project_folder) },
                 status: :ok
        else
          render json: @project_folder.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  private

  def load_current_folder
    if current_team && params[:project_folder_id].present?
      @current_folder = current_team.project_folders.find_by(id: params[:project_folder_id])
    end
  end

  def project_folders_params
    params.require(:project_folder).permit(:name, :parent_folder_id)
  end

  def check_create_permissions
    render_403 unless can_create_project_folders?(current_team)
  end
end
