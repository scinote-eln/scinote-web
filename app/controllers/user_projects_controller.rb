class UserProjectsController < ApplicationController
  before_action :load_vars
  before_action :check_view_tab_permissions, only: [ :index ]
  before_action :check_view_permissions, only: [ :index_edit ]
  before_action :check_create_permissions, only: [:new, :create]
  # TODO  check update permissions
  before_action :check_update_permisisons, only: [:update]
  before_action :check_delete_permisisons, only: [:destroy]

  def index
    @users = @project.user_projects

    respond_to do |format|
      #format.html
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "index.html.erb"
          })
        }
      }
    end
  end

  def index_edit
    @users = @project.user_projects
    @unassigned_users = @project.unassigned_users
    @up = UserProject.new(project: @project)

    respond_to do |format|
      format.json {
        render :json => {
          :project => @project,
          :html_body => render_to_string({
            :partial => "index_edit.html.erb"
          }),
          :html_footer => render_to_string({
            :partial => "index_edit_footer.html.erb"
          })
        }
      }
    end
  end

  def new
    @up = UserProject.new(
      project: @project
    )
    init_gui
  end

  def create
    @up = UserProject.new(up_params.merge(project: @project))
    @up.assigned_by = current_user

    if @up.save
      flash_success = t('user_projects.create.success_flash',
        user: @up.user.full_name,
        project: @up.project.name)

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
        format.html {
          flash[:success] = flash_success
          redirect_to projects_path
        }
        format.json {
          redirect_to :action => :index_edit, :format => :json
        }
      end
    else
       flash_error = t('user_projects.create.error_flash',
         user: @up.user.full_name,
         project: @up.project.name)
      error = t('user_projects.create.can_add_user_to_project')
      error = t('user_projects.create.select_user_role') unless @up.role

      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          init_gui
          render :new
        }
        format.json {
          render :json => {
            status: 'error',
            error: error,
            :errors => [
              flash_error
            ]
          }
        }
      end
    end
  end

  def edit
    @up = UserProject.find(params[:id])
  end

  def update
    @up = UserProject.find(params[:id])

    unless @up
      render_404
    end

    @up.role = up_params[:role]

    if @up.save
      flash_success = t(
        "user_projects.update.success_flash",
        user: @up.user.full_name,
        project: @up.project.name)

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
        format.html {
          flash[:success] = flash_success
          redirect_to projects_path
        }
        format.json {
          redirect_to :action => :index_edit, :format => :json
        }
      end
    else
      flash_error = t('user_projects.update.error_flash',
        user: @up.user.full_name,
        project: @up.project.name)

      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          init_gui
          render :new
        }
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
      flash_success = t(
        'user_projects.destroy.success_flash',
         user: @up.user.full_name,
         project: @up.project.name)

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
      generate_notification(current_user, @up.user, @project)

      respond_to do |format|
        format.html {
          flash[:success] = flash_success
          redirect_to projects_path, :status => 303
        }
        format.json {
          redirect_to project_users_edit_path(format: :json), :status => 303
        }
      end
    else
       flash_error = t('user_projects.destroy.error_flash',
         user: @up.user.full_name,
         project: @up.project.name)

      respond_to do |format|
        format.html {
          flash[:error] = flash_error
          init_gui
          # TODO handle response for html format in case of error
          render :new
        }
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
    unless @project
      render_404
    end

    if action_name == "destroy"
      @up = UserProject.find(params[:id])
      unless @up
        render_404
      end
    end
  end

  def check_view_tab_permissions
    unless can_view_project_users(@project)
      render_403
    end
  end

  def check_view_permissions
    unless can_edit_users_on_project(@project)
      render_403
    end
  end

  def check_create_permissions
    unless can_add_user_to_project(@project)
      render_403
    end
  end

  def check_update_permisisons
    # TODO improve permissions for changing your role on project
    unless params[:id] != current_user.id
      render_403
    end
  end

  def check_delete_permisisons
    # TODO improve permissions for remove yourself from project
    unless params[:id] != current_user.id
      render_403
    end
    unless can_remove_user_from_project(@project)
      render_403
    end
  end

  def generate_notification(user, target_user, project)
    title = I18n.t('activities.unassign_user_from_project',
                   unassigned_user: target_user.full_name,
                   project: project.name,
                   unassigned_by_user: user.full_name)
    message = "#{I18n.t('search.index.project')} #{@project.name}"
    notification = Notification.create(
      type_of: :assignment,
      title:
        ActionController::Base.helpers.sanitize(title),
      message:
      ActionController::Base.helpers.sanitize(message)
    )
    if target_user.assignments_notification
      UserNotification.create(notification: notification, user: target_user)
    end
  end

  def init_gui
    @users = @project.unassigned_users
  end

  def up_params
    params.require(:user_project).permit(:user_id, :project_id, :role)
  end
end
