# frozen_string_literal: true

class ProjectsController < ApplicationController
  include RenamingUtil
  include TeamsHelper
  include InputSanitizeHelper
  include ProjectsHelper
  include CardsViewHelper
  include ExperimentsHelper
  include Breadcrumbs

  attr_reader :current_folder

  helper_method :current_folder

  before_action :switch_team_with_param, only: :index
  before_action :load_vars, only: %i(show permissions edit update notifications
                                     sidebar experiments_cards view_type actions_dropdown create_tag)
  before_action :load_current_folder, only: %i(index cards new show)
  before_action :check_view_permissions, except: %i(index cards new create edit update archive_group restore_group
                                                    users_filter actions_dropdown project_filter actions_toolbar)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: :edit
  before_action :load_exp_sort_var, only: :show
  before_action :reset_invalid_view_state, only: %i(index cards show)
  before_action :set_folder_inline_name_editing, only: %i(index cards)
  before_action :set_breadcrumbs_items, only: %i(index show)
  before_action :set_navigator, only: %i(index show)
  before_action :set_current_projects_view_type, only: %i(index cards)
  layout 'fluid'

  def index; end

  def cards
    overview_service = ProjectsOverviewService.new(current_team, current_user, current_folder, params)
    title = params[:view_mode] == 'archived' ? t('projects.index.head_title_archived') : t('projects.index.head_title')

    if filters_included?
      render json: {
        toolbar_html: render_to_string(partial: 'projects/index/toolbar.html.erb'),
        filtered: true,
        cards_html: render_to_string(
          partial: 'projects/index/team_projects_grouped_by_folder.html.erb',
          locals: { projects_by_folder: overview_service.grouped_by_folder_project_cards }
        )
      }
    else
      if current_folder
        breadcrumbs_html = render_to_string(partial: 'projects/index/breadcrumbs.html.erb',
                                            locals: { target_folder: current_folder, folder_page: true })
        projects_cards_url = project_folder_cards_url(current_folder)
        title_html = if @inline_editable_title_config.present?
                       render_to_string(partial: 'shared/inline_editing',
                                        locals: {
                                          initial_value: current_folder&.name,
                                          config: @inline_editable_title_config
                                        })
                     else
                       escape_input(current_folder.name)
                     end
      else
        breadcrumbs_html = ''
        projects_cards_url = cards_projects_url
        title_html = title
      end

      cards = Kaminari.paginate_array(overview_service.project_and_folder_cards)
                      .page(params[:page] || 1).per(Constants::DEFAULT_ELEMENTS_PER_PAGE)

      render json: {
        projects_cards_url: projects_cards_url,
        breadcrumbs_html: breadcrumbs_html,
        title_html: title_html,
        next_page: cards.next_page,
        toolbar_html: render_to_string(partial: 'projects/index/toolbar.html.erb'),
        cards_html: render_to_string(
          partial: 'projects/index/team_projects.html.erb',
          locals: { cards: cards, view_mode: params[:view_mode] }
        )
      }
    end
  end

  def permissions
    if stale?([@product, current_team])
      render json: {
        editable: can_manage_project?(@project),
        moveable: can_manage_team?(current_team),
        archivable: can_archive_project?(@project),
        restorable: can_restore_project?(@project)
      }
    end
  end

  def sidebar
    @current_sort = params[:sort] || @project.current_view_state(current_user)
                                             .state.dig('experiments', params[:view_mode], 'sort')
    render json: {
      html: render_to_string(
        partial: 'shared/sidebar/experiments', locals: {
          project: @project,
          view_mode: experiments_view_mode(@project)
        }
      )
    }
  end

  def project_filter
    readable_experiments = Experiment.readable_by_user(current_user)
    managable_active_my_modules = MyModule.managable_by_user(current_user).active

    projects = Project.readable_by_user(current_user)
                      .joins(experiments: :my_modules)
                      .where(experiments: { id: readable_experiments })
                      .where(my_modules: { id: managable_active_my_modules })
                      .search(current_user, false, params[:query], 1, current_team)
                      .distinct
                      .pluck(:id, :name)

    return render plain: [].to_json if projects.blank?

    render json: projects
  end

  def new
    @project = current_team.projects.new(project_folder: current_folder)
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'projects/index/modals/new_project.html.erb'
          )
        }
      end
    end
  end

  def create
    @project = current_team.projects.new(project_params)
    @project.created_by = current_user
    @project.last_modified_by = current_user
    if @project.save
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

      log_activity(:change_project_visibility, @project, visibility: message_visibility) if message_visibility.present?
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
            @project.restore(current_user) unless @project.archived
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

  def show
    view_state = @project.current_view_state(current_user)
    @current_sort = view_state.state.dig('experiments', experiments_view_mode(@project), 'sort') || 'atoz'
    @current_view_type = view_state.state.dig('experiments', 'view_type')
    @project_is_managable = can_manage_project?(@project)
    set_inline_name_editing if @project_is_managable
  end

  def experiments_cards
    overview_service = ExperimentsOverviewService.new(@project, current_user, params)
    cards = overview_service.experiments
                            .preload(my_modules: { my_module_status: :my_module_status_implications })
                            .page(params[:page] || 1)
                            .per(Constants::DEFAULT_ELEMENTS_PER_PAGE)
    render json: {
      next_page: cards.next_page,
      cards_html: render_to_string(
        partial: 'projects/show/experiments_list',
        locals: { cards: cards,
                  view_mode: params[:view_mode],
                  filters_included: filters_included? }
      )
    }
  end

  def notifications
    @modules = @project
               .assigned_modules(current_user)
               .order(due_date: :desc)
    respond_to do |format|
      # format.html
      format.json do
        render json: {
          html: render_to_string({
                                   partial: 'notifications.html.erb'
                                 })
        }
      end
    end
  end

  def users_filter
    users = current_team.users.search(false, params[:query]).map do |u|
      { value: u.id, label: escape_input(u.name), params: { avatar_url: avatar_path(u, :icon_small) } }
    end

    render json: users, status: :ok
  end

  def view_type
    view_state = @project.current_view_state(current_user)
    view_state.state['experiments']['view_type'] = view_type_params
    view_state.save!

    render json: { cards_view_type_class: cards_view_type_class(view_type_params) }, status: :ok
  end

  def actions_dropdown
    if stale?(@project)
      render json: {
        html: render_to_string(
          partial: 'projects/index/project_actions_dropdown',
          locals: { project: @project }
        )
      }
    end
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::ProjectsService.new(
          current_user,
          project_ids: params[:project_ids].split(','),
          project_folder_ids: params[:project_folder_ids].split(',')
        ).actions
    }
  end

  private

  def project_params
    params.require(:project)
          .permit(
            :name, :team_id, :visibility,
            :archived, :project_folder_id,
            :default_public_user_role_id
          )
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

  def check_view_permissions
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

  def load_exp_sort_var
    if params[:sort]
      @project.experiments_order = params[:sort].to_s
      @project.save
    end
    @current_sort = @project.experiments_order || 'new'
  end

  def filters_included?
    %i(search created_on_from created_on_to updated_on_from updated_on_to members
       archived_on_from archived_on_to folders_search)
      .any? { |param_name| params.dig(param_name).present? }
  end

  def reset_invalid_view_state
    view_state = if action_name == 'show'
                   @project.current_view_state(current_user)
                 else
                   current_team.current_view_state(current_user)
                 end

    view_state.destroy unless view_state.valid?
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

  def set_current_projects_view_type
    if current_team
      view_state = current_team.current_view_state(current_user)
      @current_sort = view_state.state.dig('projects', projects_view_mode, 'sort') || 'atoz'
      @current_view_type = view_state.state.dig('projects', 'view_type')
    end
  end
end
