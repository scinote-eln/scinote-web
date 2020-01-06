class ProjectsController < ApplicationController
  include SampleActions
  include RenamingUtil
  include TeamsHelper
  include InputSanitizeHelper

  before_action :load_vars, only: %i(show edit update
                                     notifications reports
                                     samples experiment_archive
                                     delete_samples samples_index)
  before_action :load_projects_tree, only: %i(sidebar show samples archive
                                              experiment_archive)
  before_action :check_view_permissions, only: %i(show reports notifications
                                                  samples experiment_archive
                                                  samples_index)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: :edit
  before_action :set_inline_name_editing, only: %i(show experiment_archive)

  # except parameter could be used but it is not working.
  layout 'fluid'

  # Action defined in SampleActions
  DELETE_SAMPLES = 'Delete'.freeze

  def index
    respond_to do |format|
      format.json do
        @current_team = current_team if current_team
        @current_team ||= current_user.teams.first
        @projects = ProjectsOverviewService
                    .new(@current_team, current_user, params)
                    .project_cards
        render json: {
          html: render_to_string(
            partial: 'projects/index/team_projects.html.erb',
                     locals: { projects: @projects }
          ),
          count: @projects.size
        }
      end
      format.html do
        current_team_switch(Team.find_by_id(params[:team])) if params[:team]
        @teams = current_user.teams
        # New project for create new project modal
        @project = Project.new
        if current_team
          view_state =
            current_team.current_view_state(current_user)
          @current_filter = view_state.state.dig('projects', 'filter')
          @current_sort = view_state.state.dig('projects', 'cards', 'sort')
        end
        load_projects_tree
      end
    end
  end

  def index_dt
    @draw = params[:draw].to_i
    respond_to do |format|
      format.json do
        @current_team = current_team if current_team
        @current_team ||= current_user.teams.first
        @projects = ProjectsOverviewService
                    .new(@current_team, current_user, params)
                    .projects_datatable
      end
    end
  end

  def sidebar
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'shared/sidebar/projects.html.erb',
            formats: :html
          )
        }
      end
    end
  end

  def new
    @project = Project.new
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
        format.json {
          render json: { message: message }, status: :ok
        }
      end
    else
      respond_to do |format|
        format.json {
          render json: @project.errors, status: :unprocessable_entity
        }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "edit.html.erb",
            locals: { project: @project }
          }),
          title: t('projects.index.modal_edit_project.modal_title',
                   project: escape_input(@project.name))
        }
      }
    end
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
    # save experiments order
    if params[:sort]
      @project.experiments_order = params[:sort].to_s
      @project.save
    end
    # This is the "info" view
    current_team_switch(@project.team)
    @current_sort = @project.experiments_order || :new
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

  def samples
    @samples_index_link = samples_index_project_path(@project, format: :json)
    @team = @project.team
  end

  def experiment_archive
    current_team_switch(@project.team)
  end

  def samples_index
    @team = @project.team
    @user = current_user
    respond_to do |format|
      format.html
      format.json do
        render json: ::SampleDatatable.new(view_context,
                                           @team,
                                           @project,
                                           nil,
                                           nil,
                                           @user)
      end
    end
  end

  def dt_state_load
    respond_to do |format|
      format.json do
        render json: {
          state: current_team.current_view_state(current_user)
            .state.dig('projects', 'table')
        }
      end
    end
  end

  private

  def project_params
    params.require(:project).permit(:name, :team_id, :visibility, :archived)
  end

  def load_vars
    @project = Project.find_by_id(params[:id])

    unless @project
      render_404
    end
  end

  def load_projects_tree
    # Switch to correct team
    current_team_switch(@project.team) unless @project.nil? || @project.new_record?
    if current_user.teams.any?
      @current_team = current_team if current_team
      @current_team ||= current_user.teams.first
      @current_sort ||= 'new'
      @projects_tree = current_user.projects_tree(@current_team, @current_sort)
    else
      @projects_tree = []
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
