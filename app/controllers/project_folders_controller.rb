# frozen_string_literal: true

class ProjectFoldersController < ApplicationController
  before_action :check_manage_permissions, only: %i(move_to)

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

  private

  def check_manage_permissions
    render_403 unless can_update_team?(current_team)
  end

  def move_params
    params.require(:id)
    params.require(:movables)
    params.permit(:id, movables: %i(type id))
  end

  def move_projects(destination_folder)
    project_ids = move_params[:movables].collect { |movable| movable[:id] if movable[:type] == 'project' }.compact
    return if project_ids.blank?

    current_team.projects.where(id: project_ids).each { |p| p.update!(project_folder: destination_folder) }
  end

  def move_folders(destination_folder)
    folder_ids = move_params[:movables].collect { |movable| movable[:id] if movable[:type] == 'project_folder' }.compact
    return if folder_ids.blank?

    current_team.project_folders.where(id: folder_ids).each { |f| f.update!(parent_folder: destination_folder) }
  end
end
