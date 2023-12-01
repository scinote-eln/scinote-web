# frozen_string_literal: true

class ProjectFoldersController < ApplicationController
  include InputSanitizeHelper
  include ProjectsHelper
  include ProjectFoldersHelper

  attr_reader :current_folder
  helper_method :current_folder

  before_action :load_current_folder, only: %i(new)
  before_action :load_project_folder, only: %i(edit update)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(archive move_to)

  def tree
    render json: folders_tree(current_team, current_user)
  end

  def new
    @project_folder =
      current_team.project_folders.new(parent_folder: current_folder, archived: projects_view_mode_archived?)
    render json: {
      html: render_to_string(
        partial: 'projects/index/modals/new_project_folder'
      )
    }
  end

  def create
    project_folder = current_team.project_folders.new(project_folders_params)

    if project_folder.save
      log_activity(:create_project_folder, project_folder, project_folder: project_folder.id)
      message = t('projects.index.modal_new_project_folder.success_flash',
                  name: escape_input(project_folder.name))
      render json: { message: message }
    else
      render json: project_folder.errors, status: :unprocessable_entity
    end
  end

  def move_to
    destination_folder =
      if move_params[:destination_folder_id] == 'root_folder'
        nil
      else
        current_team.project_folders.find(move_params[:destination_folder_id])
      end

    ActiveRecord::Base.transaction do
      move_projects(destination_folder)
      move_folders(destination_folder)
    end
    render json: { message: I18n.t('projects.move.success_flash') }
  rescue StandardError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: I18n.t('projects.move.error_flash') }, status: :bad_request
  end

  def move_to_modal
    view_state = current_team.current_view_state(current_user)
    @current_sort = view_state.state.dig('projects', projects_view_mode, 'sort') || 'atoz'

    render json: {
      html: render_to_string(partial: 'projects/index/modals/move_to_modal_contents',
                             formats: :html,
                             locals: { items_label: items_label(params[:items]) })
    }
  end

  def edit
    render json: {
      html: render_to_string(partial: 'projects/index/modals/edit_folder_contents',
                             locals: { folder: @project_folder })
    }
  end

  def update
    if @project_folder.update(project_folders_params)
      log_activity(:rename_project_folder, @project_folder, project_folder: @project_folder.id)
      render json: { message: t('projects.update.success_flash', name: escape_input(@project_folder.name)) }
    else
      render json: { message: t('projects.update.error_flash', name: escape_input(@project_folder.name)),
                     errors: @project_folder.errors }, status: :unprocessable_entity
    end
  end

  def destroy_modal
    render json: {
      html: render_to_string(partial: 'projects/index/modals/project_folder_delete',
                             formats: :html,
                             locals: { project_folder_ids: params[:project_folder_ids] })
    }
  end

  def destroy
    project_folders = current_team.project_folders.where(id: params[:project_folder_ids])
    counter = 0
    project_folders.each do |folder|
      next if folder.projects.exists? || folder.project_folders.exists? || !can_manage_team?(current_team)

      folder.transaction do
        log_activity(:delete_project_folder, folder, project_folder: folder.id)
        folder.destroy!
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end
    if counter.positive?
      render json: { message: t('projects.delete_folders.success_flash', number: counter) }
    else
      render json: { error: t('projects.delete_folders.error_flash') }, status: :unprocessable_entity
    end
  end

  private

  def load_project_folder
    @project_folder = current_team.project_folders.find_by(id: params[:id])

    render_404 unless @project_folder
  end

  def load_current_folder
    if params[:project_folder_id].present?
      @current_folder = current_team.project_folders.find_by(id: params[:project_folder_id])
    end
  end

  def project_folders_params
    params.require(:project_folder).permit(:name, :parent_folder_id, :archived)
  end

  def move_params
    params.require(:destination_folder_id)
    params.require(:movables)
    params.permit(:destination_folder_id, movables: %i(id type))
  end

  def check_create_permissions
    render_403 unless can_create_project_folders?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_team?(current_team)
  end

  def move_projects(destination_folder)
    project_ids = move_params[:movables].collect { |movable| movable[:id] if movable[:type] == 'projects' }.compact
    return if project_ids.blank?

    current_team.projects.where(id: project_ids).each do |project|
      source_folder_id = project.project_folder&.id
      project.update!(project_folder: destination_folder)
      destination_folder_id = project.project_folder&.id

      log_activity(:move_project,
                   project,
                   project: project.id,
                   project_folder_to: destination_folder_id,
                   project_folder_from: source_folder_id)
    end
  end

  def move_folders(destination_folder)
    folder_ids = move_params[:movables].collect { |movable| movable[:id] if movable[:type] == 'project_folders' }.compact
    return if folder_ids.blank?

    current_team.project_folders.where(id: folder_ids).each do |folder|
      source_folder_id = folder.parent_folder&.id
      folder.update!(parent_folder: destination_folder)
      destination_folder_id = folder.parent_folder&.id

      log_activity(:move_project_folder,
                   folder,
                   project_folder: folder.id,
                   project_folder_to: destination_folder_id,
                   project_folder_from: source_folder_id)
    end
  end

  def log_activity(type_of, subject, items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of, owner: current_user, team: subject.team, subject: subject, message_items: items)
  end
end
