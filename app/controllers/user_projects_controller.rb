class UserProjectsController < ApplicationController
  include NotificationsHelper
  include InputSanitizeHelper

  before_action :load_vars
  before_action :load_user_project, only: %i(update destroy)
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
    @user_projects = @project.user_projects
    @unassigned_users = @project.unassigned_users
    @new_user_project = UserProject.new(project: @project)

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
    @user_project = @project.user_projects.new(user_project_params)
    @user_project.assigned_by = current_user

    if @user_project.save
      log_activity(:assign_user_to_project)

      respond_to do |format|
        format.json do
          redirect_to project_users_edit_path(format: :json), turbolinks: false
        end
      end
    else
      error = t('user_projects.create.can_add_user_to_project')
      error = t('user_projects.create.select_user_role') unless @user_project.role

      respond_to do |format|
        format.json do
          render json: {
            status: 'error',
            error: error
          }
        end
      end
    end
  end

  def update
    @user_project.role = user_project_params[:role]

    if @user_project.save
      log_activity(:change_user_role_on_project)

      respond_to do |format|
        format.json do
          redirect_to project_users_edit_path(format: :json), turbolinks: false
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            status: 'error',
            errors: @user_project.errors
          }
        end
      end
    end
  end

  def destroy
    if @user_project.destroy
      log_activity(:unassign_user_from_project)
      respond_to do |format|
        format.json do
          redirect_to project_users_edit_path(format: :json),
                      turbolinks: false,
                      status: :see_other
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            errors: @user_project.errors
          }
        end
      end
    end
  end

  private

  def load_vars
    @project = Project.find_by(id: params[:project_id])
    render_404 unless @project
  end

  def load_user_project
    @user_project = @project.user_projects.find(params[:id])
    render_404 unless @user_project
  end

  def check_view_permissions
    render_403 unless can_read_project?(@project)
  end

  def check_manage_users_permissions
    render_403 unless can_manage_project?(@project)
  end

  def check_create_permissions
    render_403 unless can_manage_project?(@project)
  end

  def check_manage_permissions
    render_403 unless can_manage_project?(@project) && @user_project.user_id != current_user.id
  end

  def user_project_params
    params.require(:user_project).permit(:user_id, :project_id, :role)
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @project,
            team: @project.team,
            project: @project,
            message_items: { project: @project.id,
                             user_target: @user_project.user.id,
                             role: @user_project.role_str })
  end
end
