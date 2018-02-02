class ProjectsController < ApplicationController
  include SampleActions
  include RenamingUtil
  include TeamsHelper
  include InputSanitizeHelper

  before_action :load_vars, only: [:show, :edit, :update,
                                   :notifications, :reports,
                                   :samples, :experiment_archive,
                                   :delete_samples, :samples_index]
  before_action :check_view_permissions, only: %i(show reports notifications
                                                  samples experiment_archive
                                                  samples_index)
  before_action :check_create_permissions, only: [ :new, :create ]
  before_action :check_manage_permissions, only: %i(edit update)

  @filter_by_archived = false

  # except parameter could be used but it is not working.
  layout :choose_layout

  # Action defined in SampleActions
  DELETE_SAMPLES = 'Delete'.freeze

  def index
    if params[:team]
      current_team_switch(Team.find_by_id(params[:team]))
    end

    if current_user.teams.any?
      @current_team_id = current_team.id if current_team

      @current_team_id ||= current_user.teams.first.id
      @current_sort = params[:sort].to_s
      @projects_by_teams = current_user.projects_by_teams(@current_team_id,
                                                          @current_sort,
                                                          @filter_by_archived)
    else
      @projects_by_teams = []
    end

    @teams = current_user.teams

    # New project for create new project modal
    @project = Project.new
  end

  def archive
    @filter_by_archived = true
    index
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

      # Create "project created" activity
      Activity.create(
        type_of: :create_project,
        user: current_user,
        project: @project,
        message: t(
          "activities.create_project",
          user: current_user.full_name,
          project: @project.name
        )
      )

      flash[:success] = t("projects.create.success_flash", name: @project.name)
      respond_to do |format|
        format.json {
          render json: { url: projects_path }, status: :ok
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
    flash_error = t('projects.update.error_flash', name: @project.name)

    # Check archive permissions if archiving/restoring
    if project_params.include? :archive
      if (project_params[:archive] && !can_manage_project?(@project)) ||
         (!project_params[:archive] && !can_restore_project?(@project))
        return_error = true
        is_archive = URI(request.referer).path == projects_archive_path ? "restore" : "archive"
        flash_error = t("projects.#{is_archive}.error_flash", name: @project.name)
      end
    end

    message_renamed = nil
    message_visibility = nil
    if project_params.include? :name and
      project_params[:name] != @project.name then
      message_renamed = t(
        "activities.rename_project",
        user: current_user.full_name,
        project_old: @project.name,
        project_new: project_params[:name]
      )
    end
    if project_params.include? :visibility and
      project_params[:visibility] != @project.visibility then
      message_visibility = t(
        "activities.change_project_visibility",
        user: current_user.full_name,
        project: @project.name,
        visibility: project_params[:visibility] == "visible" ?
          t("general.public") :
          t("general.private")
      )
    end

    @project.last_modified_by = current_user
    if @project.update(project_params)
      # Add activities if needed
      if message_visibility.present?
        Activity.create(
          type_of: :change_project_visibility,
          user: current_user,
          project: @project,
          message: message_visibility
        )
      end
      if message_renamed.present?
        Activity.create(
          type_of: :rename_project,
          user: current_user,
          project: @project,
          message: message_renamed
        )
      end

      flash_success = t('projects.update.success_flash', name: @project.name)
      respond_to do |format|
        format.html {
          # Redirect URL for archive view is different as for other views.
          if URI(request.referer).path == projects_archive_path
            # The project should be restored
            unless @project.archived
              @project.restore(current_user)

              # "Restore project" activity
              Activity.create(
                type_of: :restore_project,
                user: current_user,
                project: @project,
                message: t(
                  "activities.restore_project",
                  user: current_user.full_name,
                  project: @project.name
                )
              )

              flash_success = t('projects.restore.success_flash',
                name: @project.name)
            end
            redirect_to projects_archive_path
          else
            # The project should be archived
            if @project.archived
              @project.archive(current_user)

              # "Archive project" activity
              Activity.create(
                type_of: :archive_project,
                user: current_user,
                project: @project,
                message: t(
                  "activities.archive_project",
                  user: current_user.full_name,
                  project: @project.name
                )
              )

              flash_success = t('projects.archive.success_flash', name: @project.name)
            end
            redirect_to projects_path
          end
          flash[:success] = flash_success
        }
        format.json {
          render json: {
            status: :ok,
            html: render_to_string({
              partial: "projects/index/project.html.erb",
              locals: { project: @project }
              })
          }
        }
      end
    else
      return_error = true
    end

    if return_error then
      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          # Redirect URL for archive view is different as for other views.
          if URI(request.referer).path == projects_archive_path
            redirect_to projects_archive_path
          else
            redirect_to projects_path
          end
        }
        format.json {
          render json: @project.errors,
            status: :unprocessable_entity
        }
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
    @current_sort = @project.experiments_order
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

  def check_view_permissions
    render_403 unless can_read_project?(@project)
  end

  def check_create_permissions
    render_403 unless can_create_projects?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_project?(@project)
  end

  def choose_layout
    action_name.in?(['index', 'archive']) ? 'main' : 'fluid'
  end
end
