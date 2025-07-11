# frozen_string_literal: true

class ProjectsController < ApplicationController
  include RenamingUtil
  include TeamsHelper
  include InputSanitizeHelper
  include ProjectsHelper
  include CardsViewHelper
  include ExperimentsHelper
  include Breadcrumbs
  include UserRolesHelper
  include FavoritesActions

  attr_reader :current_folder

  helper_method :current_folder

  before_action :switch_team_with_param, only: :index
  before_action :load_vars, only: %i(update create_tag assigned_users_list show)
  before_action :load_current_folder, only: :index
  before_action :check_read_permissions, except: %i(index create update archive_group restore_group
                                                    inventory_assigning_project_filter
                                                    actions_toolbar user_roles users_filter head_of_project_users_list
                                                    favorite unfavorite)
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, only: :update
  before_action :set_folder_inline_name_editing, only: %i(index)
  before_action :set_breadcrumbs_items, only: :index
  before_action :set_navigator, only: :index
  layout 'fluid'

  def index
    respond_to do |format|
      format.json do
        projects = Lists::ProjectsService.new(current_team, current_user, current_folder, params).call
        render json: projects, each_serializer: Lists::ProjectAndFolderSerializer, user: current_user,
               meta: pagination_dict(projects)
      end
      format.html do
        render 'projects/index'
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: @project, serializer: ProjectSerializer, user: current_user
      end
      format.html do
        render 'experiments/index'
      end
    end
  end

  def inventory_assigning_project_filter
    viewable_experiments = Experiment.viewable_by_user(current_user, current_team)
    assignable_my_modules = MyModule.repository_row_assignable_by_user(current_user)

    projects = Project.viewable_by_user(current_user, current_team)
                      .active
                      .joins(experiments: :my_modules)
                      .where(experiments: { id: viewable_experiments })
                      .where(my_modules: { id: assignable_my_modules })
                      .order(:name)
                      .distinct
                      .pluck(:id, :name)

    return render plain: [].to_json if projects.blank?

    render json: projects
  end

  def create
    @project = current_team.projects.new(project_params)
    @project.created_by = current_user
    @project.last_modified_by = current_user
    if @project.save
      log_activity(:create_project)

      message = t('projects.create.success_flash', name: escape_input(@project.name))
      render json: { message: message }, status: :ok
    else
      render json: @project.errors, status: :unprocessable_entity
    end
  end

  def update
    default_public_user_role_name_before_update = @project.default_public_user_role&.name
    old_status = @project.status
    @project.assign_attributes(project_update_params)
    return_error = false
    flash_error = t('projects.update.error_flash', name: escape_input(@project.name))

    return render_403 unless can_manage_project?(@project) || @project.archived_changed?

    # Check archive permissions if archiving/restoring
    if @project.archived_changed? &&
       ((@project.archived == 'true' && !can_archive_project?(@project)) ||
       (@project.archived == 'false' && !can_restore_project?(@project)))
        return_error = true
        is_archive = @project.archived? ? 'archive' : 'restore'
        flash_error =
          t("projects.#{is_archive}.error_flash", name: escape_input(@project.name))
    end

    message_edited = @project.name_changed? || @project.description_changed?
    message_visibility = if !@project.visibility_changed?
                           nil
                         elsif @project.visible?
                           t('projects.activity.visibility_visible')
                         else
                           t('projects.activity.visibility_hidden')
                         end

    message_archived = if !@project.archived_changed?
                         nil
                       elsif @project.archived?
                         'archive'
                       else
                         'restore'
                       end
    supervised_by_id_changes = @project.changes[:supervised_by_id]
    start_date_changes = @project.changes[:start_date]
    due_date_changes = @project.changes[:due_date]

    default_public_user_role_name = nil
    if !@project.visibility_changed? && @project.default_public_user_role_id_changed?
      @project.visibility_will_change! # triggers assignment sync
      default_public_user_role_name = UserRole.find(project_params[:default_public_user_role_id]).name
    end

    @project.last_modified_by = current_user
    if !return_error && @project.save

      # Add activities if needed
      if message_visibility.present? && @project.visible?
        log_activity(:project_grant_access_to_all_team_members,
                     @project,
                     { visibility: message_visibility,
                       role: @project.default_public_user_role.name,
                       team: @project.team.id })
      end
      if message_visibility.present? && !@project.visible?
        log_activity(:project_remove_access_from_all_team_members,
                     @project,
                     { visibility: message_visibility,
                       role: default_public_user_role_name_before_update,
                       team: @project.team.id })
      end

      log_activity(:edit_project) if message_edited.present?
      log_activity(:archive_project) if message_archived == 'archive'
      log_activity(:restore_project) if message_archived == 'restore'

      if default_public_user_role_name.present?
        log_activity(:project_access_changed_all_team_members,
                     @project,
                     { team: @project.team.id, role: default_public_user_role_name })
      end

      if supervised_by_id_changes.present?
        log_activity(:remove_head_of_project, @project, { user_target: supervised_by_id_changes[0] }) if supervised_by_id_changes[0].present? # remove head of project
        log_activity(:set_head_of_project, @project, { user_target: supervised_by_id_changes[1] }) if supervised_by_id_changes[1].present? # add head of project
      end

      if old_status != @project.status
        log_activity(:change_project_status, @project, { old_status: I18n.t("projects.index.status.#{old_status}"),
                                                         status: I18n.t("projects.index.status.#{@project.status}") })
      end

      log_start_date_change_activity(start_date_changes) if start_date_changes.present?
      log_due_date_change_activity(due_date_changes) if due_date_changes.present?

      flash_success = t('projects.update.success_flash', name: escape_input(@project.name))
      if message_archived == 'archive'
        flash_success = t('projects.archive.success_flash', name: escape_input(@project.name))
      elsif message_archived == 'restore'
        flash_success = t('projects.restore.success_flash', name: escape_input(@project.name))
      end
      respond_to do |format|
        format.html do
          @project.restore(current_user) if message_archived == 'restore'
          @project.archive(current_user) if message_archived == 'archive'

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

  def archive_group
    projects = current_team.projects.active.where(id: params[:project_ids])
    counter = 0
    projects.each do |project|
      next unless can_archive_project?(project)

      project.transaction do
        project.archive!(current_user)
        log_activity(:archive_project, project)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end
    if counter.positive?
      render json: { message: t('projects.archive_group.success_flash', number: counter) }
    else
      render json: { message: t('projects.archive_group.error_flash') }, status: :unprocessable_entity
    end
  end

  def create_tag
    render_403 unless can_manage_project_tags?(@project)

    @tag = @project.tags.create(tag_params.merge({
                                                   created_by: current_user,
                                                   last_modified_by: current_user,
                                                   color: Constants::TAG_COLORS.sample
                                                 }))

    render json: {
      tag: {
        id: @tag.id,
        name: @tag.name,
        color: @tag.color
      }
    }
  end

  def restore_group
    projects = current_team.projects.archived.where(id: params[:project_ids])
    counter = 0
    projects.each do |project|
      next unless can_restore_project?(project)

      project.transaction do
        project.restore!(current_user)
        log_activity(:restore_project, project)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end
    if counter.positive?
      render json: { message: t('projects.restore_group.success_flash', number: counter) }
    else
      render json: { message: t('projects.restore_group.error_flash') }, status: :unprocessable_entity
    end
  end

  def users_filter
    users = current_team.users.search(false, params[:query]).map do |u|
      [u.id, u.name, { avatar_url: avatar_path(u, :icon_small) }]
    end

    render json: { data: users }, status: :ok
  end

  def head_of_project_users_list
    users = User.where(id: current_team.projects.select(:supervised_by_id)).map do |u|
      [u.id, u.name, { avatar_url: avatar_path(u, :icon_small) }]
    end

    render json: { data: users }, status: :ok
  end

  def assigned_users_list
    users = @project.users.search(false, params[:query]).order(:full_name)

    render json: { data: users.map { |u| [u.id, u.name, { avatar_url: avatar_path(u, :icon_small) }] } }, status: :ok
  end

  def user_roles
    render json: { data: user_roles_collection(Project.new).map(&:reverse) }
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::ProjectsService.new(
          current_user,
          items: JSON.parse(params[:items])
        ).actions
    }
  end

  private

  def project_params
    params.require(:project)
          .permit(
            :name, :visibility,
            :archived, :project_folder_id,
            :default_public_user_role_id,
            :due_date,
            :start_date,
            :description
          )
  end

  def project_update_params
    params.require(:project)
          .permit(:name, :visibility, :archived, :default_public_user_role_id, :due_date, :start_date, :description, :status, :supervised_by_id)
  end

  def view_type_params
    params.require(:project).require(:view_type)
  end

  def load_vars
    @project = Project.find_by(id: params[:id] || params[:project_id])

    render_404 unless @project
  end

  def tag_params
    params.require(:tag).permit(:name)
  end

  def load_current_folder
    if current_team && params[:project_folder_id].present?
      @current_folder = current_team.project_folders.find_by(id: params[:project_folder_id])
    elsif @project&.project_folder
      @current_folder = @project&.project_folder
    end
  end

  def check_read_permissions
    current_team_switch(@project.team) if current_team != @project.team
    render_403 unless can_read_project?(@project)
  end

  def check_create_permissions
    render_403 unless can_create_projects?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_project?(@project)
  end

  def set_inline_name_editing
    @inline_editable_title_config = {
      name: 'title',
      params_group: 'project',
      item_id: @project.id,
      field_to_udpate: 'name',
      path_to_update: project_path(@project)
    }
  end

  def set_folder_inline_name_editing
    return if !can_manage_team?(current_team) || @current_folder.nil?

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'project_folder',
      item_id: @current_folder.id,
      field_to_udpate: 'name',
      path_to_update: project_folder_path(@current_folder)
    }
  end

  def log_start_date_change_activity(start_date_changes)
    type_of = if start_date_changes[0].nil?     # set start_date
                message_items = { start_date: @project.start_date }
                :set_project_start_date
              elsif start_date_changes[1].nil?  # remove start_date
                message_items = { start_date: start_date_changes[0] }
                :remove_project_start_date
              else                              # change start_date
                message_items = { start_date: @project.start_date }
                :change_project_start_date
              end
    log_activity(type_of, @project, message_items)
  end

  def log_due_date_change_activity(due_date_changes)
    type_of = if due_date_changes[0].nil?     # set due_date
                message_items = { due_date: @project.due_date }
                :set_project_due_date
              elsif due_date_changes[1].nil?  # remove due_date
                message_items = { due_date: due_date_changes[0] }
                :remove_project_due_date
              else                            # change due_date
                message_items = { due_date: @project.due_date }
                :change_project_due_date
              end
    log_activity(type_of, @project, message_items)
  end

  def log_activity(type_of, project = nil, message_items = {})
    project ||= @project
    message_items = { project: project.id }.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: project,
            team: project.team,
            project: project,
            message_items: message_items)
  end

  def set_navigator
    @navigator = if @project
                   {
                     url: tree_navigator_project_path(@project),
                     archived: params[:view_mode] == 'archived',
                     id: @project.code
                   }
                 elsif current_folder
                   {
                     url: tree_navigator_project_folder_path(current_folder),
                     archived: params[:view_mode] == 'archived',
                     id: current_folder.code
                   }
                 else
                   {
                     url: navigator_projects_path,
                     archived: params[:view_mode] == 'archived'
                   }
                 end
  end
end
