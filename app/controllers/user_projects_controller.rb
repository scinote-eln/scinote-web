class UserProjectsController < ApplicationController
  include NotificationsHelper
  include InputSanitizeHelper

  before_action :load_vars
  before_action :load_up_var, only: %i(update destroy)
  before_action :check_view_permissions, only: :index
  before_action :check_manage_users_permissions, only: :index_edit
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: %i(update destroy)

  def index
    @users = @project.user_projects

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'index.html.erb'
          ),
          project_id: @project.id,
          counter: @project.users.count # Used for counter badge
        }
      end
    end
  end

  def index_edit
    @users = @project.user_projects
    @unassigned_users = @project.unassigned_users
    @up = UserProject.new(project: @project)

    respond_to do |format|
      format.json do
        render json: {
          project: @project,
          html_header: t('projects.index.modal_manage_users.modal_title_html',
                         name: @project.name),
          html_body: render_to_string(
            partial: 'index_edit.html.erb'
          ),
          html_footer: render_to_string(
            partial: 'index_edit_footer.html.erb'
          )
        }
      end
    end
  end

  def create
    @up = UserProject.new(up_params.merge(project: @project))
    @up.assigned_by = current_user

    if @up.save
      # Generate activity
      Activity.create(
        type_of: :assign_user_to_project,
        user: current_user,
        project: @project,
        message: t(
          "activities.assign_user_to_project",
          assigned_user: @up.user.full_name,
          role: @up.role_str,
          project: @project.name,
          assigned_by_user: current_user.full_name
        )
      )

      respond_to do |format|
        format.json do
          redirect_to project_users_edit_path(format: :json), turbolinks: false
        end
      end
    else
      error = t('user_projects.create.can_add_user_to_project')
      error = t('user_projects.create.select_user_role') unless @up.role

      respond_to do |format|
        format.json {
          render :json => {
            status: 'error',
            error: error
          }
        }
      end
    end
  end

  def update
    @up.role = up_params[:role]

    if @up.save
      # Generate activity
      Activity.create(
        type_of: :change_user_role_on_project,
        user: current_user,
        project: @project,
        message: t(
          "activities.change_user_role_on_project",
          actor: current_user.full_name,
          user: @up.user.full_name,
          project: @project.name,
          role: @up.role_str
        )
      )

      respond_to do |format|
        format.json do
          redirect_to project_users_edit_path(format: :json), turbolinks: false
        end
      end
    else
      respond_to do |format|
        format.json {
          render :json => {
            status: 'error',
            :errors => [
              flash_error
            ]
          }
        }
      end
    end
  end

  def destroy
    if @up.destroy
      # Generate activity
      Activity.create(
        type_of: :unassign_user_from_project,
        user: current_user,
        project: @project,
        message: t(
          "activities.unassign_user_from_project",
          unassigned_user: @up.user.full_name,
          project: @project.name,
          unassigned_by_user: current_user.full_name
        )
      )
      generate_notification(current_user, @up.user, false, false, @project)

      respond_to do |format|
        format.json do
          redirect_to project_users_edit_path(format: :json),
                      turbolinks: false,
                      status: 303
        end
      end
    else
      respond_to do |format|
        format.json {
          render :json => {
            :errors => [
              flash_error
            ]
          }
        }
      end
    end
  end

  private

  def load_vars
    @project = Project.find_by_id(params[:project_id])
    render_404 unless @project
  end

  def load_up_var
    @up = UserProject.find(params[:id])
    render_404 unless @up
  end

  def check_view_permissions
    render_403 unless can_read_project?(@project)
  end

  def check_manage_users_permissions
    render_403 unless can_manage_project?(@project)
  end

  def check_create_permissions
    render_403 unless can_create_projects?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_project?(@project) &&
                      @up.user_id != current_user.id
  end

  def init_gui
    @users = @project.unassigned_users
  end

  def up_params
    params.require(:user_project).permit(:user_id, :project_id, :role)
  end
end
