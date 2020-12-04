# frozen_string_literal: true

class ProjectFoldersController < ApplicationController
  include InputSanitizeHelper

  before_action :load_current_folder, only: %i(new)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(move_to)

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
    project_folder = current_team.project_folders.new(project_folders_params)

    respond_to do |format|
      format.json do
        if project_folder.save
          log_activity(:create_project_folder, project_folder, { project_folder: project_folder.id })
          message = t('projects.index.modal_new_project_folder.success_flash',
                      name: escape_input(project_folder.name))
          render json: { message: message }
        else
          render json: project_folder.errors,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def move_to
    destination_folder = current_team.project_folders.find(move_params[:id])
    destination_folder.transaction do
      move_projects(destination_folder)
      move_folders(destination_folder)
    end
    respond_to do |format|
      format.json { render json: { flash: I18n.t('projects.move.success_flash') } }
    end
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    respond_to do |format|
      format.json { render json: { flash: I18n.t('projects.move.error_flash') }, status: :bad_request }
    end
  end

  def update
    folder = current_team.project_folders.find(params[:id])

    log_activity(:rename_project_folder, folder, { project_folder: folder.id })
  end

  def archive
    folder = current_team.project_folders.find(params[:id])

    log_activity(:archive_project_folder, folder, { project_folder: folder.id })
  end

  private

  def load_current_folder
    if params[:project_folder_id].present?
      @current_folder = current_team.project_folders.find_by(id: params[:project_folder_id])
    end
  end

  def project_folders_params
    params.require(:project_folder).permit(:name, :parent_folder_id)
  end

  def move_params
    params.require(:id)
    params.require(:movables)
    params.permit(:id, movables: %i(type id))
  end

  def check_create_permissions
    render_403 unless can_create_project_folders?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_update_team?(current_team)
  end

  def move_projects(destination_folder)
    project_ids = move_params[:movables].collect { |movable| movable[:id] if movable[:type] == 'project' }.compact
    return if project_ids.blank?

    current_team.projects.where(id: project_ids).each do |project|
      source_folder_name = project.project_folder&.name || I18n.t('global_activities.root_folder_level')
      project.update!(project_folder: destination_folder)
      destination_folder_name = project.project_folder&.name || I18n.t('global_activities.root_folder_level')

      log_activity(:move_project, project, { project: project.id,
                                             destination_folder: destination_folder_name,
                                             source_folder: source_folder_name })
    end
  end

  def move_folders(destination_folder)
    folder_ids = move_params[:movables].collect { |movable| movable[:id] if movable[:type] == 'project_folder' }.compact
    return if folder_ids.blank?

    current_team.project_folders.where(id: folder_ids).each do |folder|
      source_folder_name = folder.parent_folder&.name || I18n.t('global_activities.root_folder_level')
      folder.update!(parent_folder: destination_folder)
      destination_folder_name = folder.parent_folder&.name || I18n.t('global_activities.root_folder_level')

      log_activity(:move_project_folder, folder, { project_folder: folder.id,
                                                   destination_folder: destination_folder_name,
                                                   source_folder: source_folder_name })
    end
  end

  def log_activity(type_of, subject, items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of, owner: current_user, team: subject.team, subject: subject, message_items: items)
  end
end
