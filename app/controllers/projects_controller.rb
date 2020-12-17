# frozen_string_literal: true

class ProjectsController < ApplicationController
  include RenamingUtil
  include TeamsHelper
  include InputSanitizeHelper
  include ProjectsHelper

  before_action :switch_team_with_param, only: :index
  before_action :load_vars, only: %i(show edit update notifications experiment_archive sidebar)
  before_action :load_current_folder, only: %i(index cards)
  before_action :check_view_permissions, only: %i(show notifications experiment_archive sidebar)
  before_action :check_create_permissions, only: %i(create)
  before_action :check_manage_permissions, only: :edit
  before_action :set_inline_name_editing, only: %i(show)
  before_action :load_exp_sort_var, only: %i(show experiment_archive)

  layout 'fluid'

  def index
    if current_team
      view_state = current_team.current_view_state(current_user)
      @current_filter = view_state.state.dig('projects', 'filter')
      @current_sort = view_state.state.dig('projects', 'cards', 'sort')
    end
  end

  def cards
    overview_service = ProjectsOverviewService.new(current_team, current_user, @current_folder, params)

    if params[:search].present?
      render json: {
        cards_html: render_to_string(
          partial: 'projects/index/team_projects_grouped_by_folder.html.erb',
          locals: { projects_by_folder: overview_service.grouped_by_folder_project_cards }
        )
      }
    else
      render json: {
        projects_cards_url: @current_folder ? project_folder_cards_url(@current_folder) : cards_projects_url,
        breadcrumbs_html: @current_folder ? render_to_string(partial: 'projects/index/breadcrumbs.html.erb') : '',
        cards_html: render_to_string(
          partial: 'projects/index/team_projects.html.erb',
          locals: { cards: overview_service.project_and_folder_cards }
        )
      }
    end
  end

  def sidebar
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'shared/sidebar/experiments.html.erb', locals: { project: @project }
          )
        }
      end
    end
  end

  def create
    @project = Project.new(project_params)
    @project.created_by = current_user
    @project.last_modified_by = current_user
    if current_team.id == project_params[:team_id].to_i &&
       @project.save
      # Create user-project association
      up = UserProject.new(
        role: :owner,
        user: current_user,
        project: @project
      )
      up.save
      log_activity(:create_project)

      message = t('projects.create.success_flash', name: escape_input(@project.name))
      respond_to do |format|
        format.json do
          render json: { message: message }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: @project.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    render json: {
      html: render_to_string(partial: 'projects/index/modals/edit_project_contents.html.erb',
                             locals: { project: @project })

    }
  end

  def update
    return_error = false
    flash_error = t('projects.update.error_flash', name: escape_input(@project.name))

    # Check archive permissions if archiving/restoring
    if project_params.include? :archived
      if (project_params[:archived] == 'true' &&
          !can_archive_project?(@project)) ||
         (project_params[:archived] == 'false' &&
           !can_restore_project?(@project))
        return_error = true
        is_archive = project_params[:archived] == 'true' ? 'archive' : 'restore'
        flash_error =
          t("projects.#{is_archive}.error_flash", name: escape_input(@project.name))
      end
    elsif !can_manage_project?(@project)
      render_403 && return
    end

    message_renamed = nil
    message_visibility = nil
    if (project_params.include? :name) &&
       (project_params[:name] != @project.name)
      message_renamed = true
    end
    if (project_params.include? :visibility) &&
       (project_params[:visibility] != @project.visibility)
      message_visibility = if project_params[:visibility] == 'visible'
                             t('projects.activity.visibility_visible')
                           else
                             t('projects.activity.visibility_hidden')
                           end
    end

    @project.last_modified_by = current_user
    if !return_error && @project.update(project_params)
      # Add activities if needed

      log_activity(:change_project_visibility, visibility: message_visibility) if message_visibility.present?
      log_activity(:rename_project) if message_renamed.present?
      log_activity(:archive_project) if project_params[:archived] == 'true'
      log_activity(:restore_project) if project_params[:archived] == 'false'

      flash_success = t('projects.update.success_flash', name: escape_input(@project.name))
      if project_params[:archived] == 'true'
        flash_success = t('projects.archive.success_flash', name: escape_input(@project.name))
      elsif project_params[:archived] == 'false'
        flash_success = t('projects.restore.success_flash', name: escape_input(@project.name))
      end
      respond_to do |format|
        format.html do
          # Redirect URL for archive view is different as for other views.
          if project_params[:archived] == 'false'
            # The project should be restored
            unless @project.archived
              @project.restore(current_user)
            end
          elsif @project.archived
            # The project should be archived
            @project.archive(current_user)
          end
          redirect_to projects_path
          flash[:success] = flash_success
        end
        format.json do
          render json: {
            status: :ok,
            message: flash_success
          }
        end
      end
    else
      return_error = true
    end

    if return_error
      respond_to do |format|
        format.html do
          flash[:error] = flash_error
          # Redirect URL for archive view is different as for other views.
          if URI(request.referer).path == projects_archive_path
            redirect_to projects_archive_path
          else
            redirect_to projects_path
          end
        end
        format.json do
          render json: { message: flash_error, errors: @project.errors },
                 status: :unprocessable_entity
        end
      end
    end
  end

  def show
    redirect_to action: :experiment_archive if @project.archived?
    # This is the "info" view
    current_team_switch(@project.team)
  end

  def notifications
    @modules = @project
      .assigned_modules(current_user)
      .order(due_date: :desc)
    respond_to do |format|
      #format.html
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "notifications.html.erb"
          })
        }
      }
    end
  end

  def experiment_archive
    current_team_switch(@project.team)
  end

  def dt_state_load
    render json: { state: current_team&.current_view_state(current_user)&.state&.dig('projects', 'table') }
  end

  def users_filter
    users = current_team.users.map do |u|
      { value: u.id, label: sanitize_input(u.name), params: { avatar_url: avatar_path(u, :icon_small) } }
    end

    render json: users, status: :ok
  end

  private

  def project_params
    params.require(:project).permit(:name, :team_id, :visibility, :archived)
  end

  def load_vars
    @project = Project.find_by(id: params[:id])

    render_404 unless @project
  end

  def load_current_folder
    if current_team && params[:project_folder_id].present?
      @current_folder = current_team.project_folders.find_by(id: params[:project_folder_id])
    end
  end

  def check_view_permissions
    render_403 unless can_read_project?(@project)
  end

  def check_create_permissions
    render_403 unless can_create_projects?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_project?(@project)
  end

  def set_inline_name_editing
    return unless can_manage_project?(@project)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'project',
      item_id: @project.id,
      field_to_udpate: 'name',
      path_to_update: project_path(@project)
    }
  end

  def load_exp_sort_var
    if params[:sort]
      @project.experiments_order = params[:sort].to_s
      @project.save
    end
    @current_sort = @project.experiments_order || 'new'
    @current_sort = 'new' if @current_sort.include?('arch') && action_name != 'experiment_archive'
  end

  def log_activity(type_of, message_items = {})
    message_items = { project: @project.id }.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @project,
            team: @project.team,
            project: @project,
            message_items: message_items)
  end
end
