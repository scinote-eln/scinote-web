# frozen_string_literal: true

class ExperimentsController < ApplicationController
  include TeamsHelper
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers
  include Breadcrumbs

  before_action :load_project, only: %i(new create archive_group restore_group)
  before_action :load_experiment, except: %i(new create archive_group restore_group
                                             inventory_assigning_experiment_filter actions_toolbar)
  before_action :check_read_permissions, except: %i(edit archive clone move new
                                                    create archive_group restore_group
                                                    inventory_assigning_experiment_filter actions_toolbar)
  before_action :check_canvas_read_permissions, only: %i(canvas)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(edit batch_clone_my_modules)
  before_action :check_update_permissions, only: %i(update)
  before_action :check_archive_permissions, only: :archive
  before_action :check_clone_permissions, only: %i(clone_modal clone)
  before_action :check_move_permissions, only: %i(move_modal move)
  before_action :set_inline_name_editing, only: %i(canvas table module_archive)
  before_action :set_breadcrumbs_items, only: %i(canvas table module_archive)
  before_action :set_navigator, only: %i(canvas module_archive table)

  layout 'fluid'

  def new
    @experiment = Experiment.new
    render json: {
      html: render_to_string(
        partial: 'new_modal', formats: :html
      )
    }
  end

  def create
    @experiment = Experiment.new(experiment_params)
    @experiment.created_by = current_user
    @experiment.last_modified_by = current_user
    @experiment.project = @project
    if @experiment.save
      experiment_annotation_notification
      log_activity(:create_experiment, @experiment)
      flash[:success] = t('experiments.create.success_flash',
                          experiment: @experiment.name)

      render json: { path: my_modules_experiment_url(@experiment) }, status: :ok
    else
      render json: @experiment.errors, status: :unprocessable_entity
    end
  end

  def show
    render json: {
      html: render_to_string(partial: 'experiments/details_modal', formats: :html)
    }
  end

  def permissions
    if stale?([@experiment, @experiment.project])
      render json: {
        editable: can_manage_experiment?(@experiment),
        moveable: can_move_experiment?(@experiment),
        archivable: can_archive_experiment?(@experiment),
        restorable: can_restore_experiment?(@experiment),
        duplicable: can_clone_experiment?(@experiment)
      }
    end
  end

  def canvas
    @project = @experiment.project
    @active_modules = unless @experiment.archived_branch?
                        @experiment.my_modules.active.order(:name)
                                   .left_outer_joins(:designated_users, :task_comments)
                                   .preload(:tags, outputs: :to)
                                   .preload(:my_module_status, :my_module_group, user_assignments: %i(user user_role))
                                   .select('COUNT(DISTINCT users.id) as designated_users_count')
                                   .select('COUNT(DISTINCT comments.id) as task_comments_count')
                                   .select('my_modules.*').group(:id)
                      end
  end

  def table
    @project = @experiment.project
    @experiment.current_view_state(current_user)
    @my_module_visible_table_columns = current_user.my_module_visible_table_columns

    view_state = @experiment.current_view_state(current_user)
    @current_sort = view_state.state.dig('my_modules', my_modules_view_mode(@project), 'sort') || 'atoz'
  end

  def my_modules_view_mode(my_module)
    return 'archived' if  my_module.archived?

    params[:view_mode] == 'archived' ? 'archived' : 'active'
  end

  def load_table
    active_view_mode = params[:view_mode] != 'archived'
    my_modules = nil

    unless @experiment.archived_branch? && active_view_mode
      my_modules = @experiment.my_modules.readable_by_user(current_user)

      unless @experiment.archived_branch?
        my_modules = if active_view_mode
                       my_modules.active
                     else
                       my_modules.archived
                     end
      end
    end

    render json: Experiments::TableViewService.new(@experiment, my_modules, current_user, params).call
  end

  def my_modules
    view_state = @experiment.current_view_state(current_user)
    view_type = view_state.state['my_modules']['view_type'] || 'canvas'

    redirect_to view_mode_redirect_url(view_type)
  end

  def view_type
    view_state = @experiment.current_view_state(current_user)
    view_state.state['my_modules']['view_type'] = view_type_params
    view_state.save!

    redirect_to view_mode_redirect_url(view_type_params)
  end

  def edit
    render json: {
      html: render_to_string(partial: 'edit_modal', formats: :html)
    }
  end

  def update
    old_text = @experiment.description
    @experiment.assign_attributes(experiment_params)
    @experiment.last_modified_by = current_user
    name_changed = @experiment.name_changed?
    description_changed = @experiment.description_changed?

    if @experiment.save
      experiment_annotation_notification(old_text) if old_text

      activity_type = if experiment_params[:archived] == 'false'
                        :restore_experiment
                      elsif name_changed && !description_changed
                        :rename_experiment
                      else
                        :edit_experiment
                      end
      log_activity(activity_type, @experiment)

      respond_to do |format|
        format.json do
          render json: {}, status: :ok
        end
        format.html do
          flash[:success] = t('experiments.update.success_flash', experiment: @experiment.name)
          redirect_to project_path(@experiment.project)
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: @experiment.errors, status: :unprocessable_entity
        end
        format.html do
          flash[:alert] = t('experiments.update.error_flash')
          redirect_back(fallback_location: root_path)
        end
      end
    end
  end

  def archive
    @experiment.archive(current_user)
    if @experiment.save
      log_activity(:archive_experiment, @experiment)
      flash[:success] = t('experiments.archive.success_flash',
                          experiment: @experiment.name)

      redirect_to project_path(@experiment.project)
    else
      flash[:alert] = t('experiments.archive.error_flash')
      redirect_back(fallback_location: root_path)
    end
  end

  def archive_group
    experiments = @project.experiments.active.where(id: params[:experiment_ids])
    counter = 0
    experiments.each do |experiment|
      next unless can_archive_experiment?(experiment)

      experiment.transaction do
        experiment.archived_on = DateTime.now
        experiment.archive!(current_user)
        log_activity(:archive_experiment, experiment)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end
    if counter.positive?
      render json: { message: t('experiments.archive_group.success_flash', number: counter) }
    else
      render json: { message: t('experiments.archive_group.error_flash') }, status: :unprocessable_entity
    end
  end

  def restore_group
    experiments = @project.experiments.archived.where(id: params[:experiment_ids])
    counter = 0
    experiments.each do |experiment|
      next unless can_restore_experiment?(experiment)

      experiment.transaction do
        experiment.restore!(current_user)
        log_activity(:restore_experiment, experiment)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end
    if counter.positive?
      render json: { message: t('experiments.restore_group.success_flash', number: counter) }
    else
      render json: { message: t('experiments.restore_group.error_flash') }, status: :unprocessable_entity
    end
  end

  # GET: clone_modal_experiment_path(id)
  def clone_modal
    @projects = @experiment.project.team.projects.active
                           .with_user_permission(current_user, ProjectPermissions::EXPERIMENTS_CREATE)
    render json: {
      html: render_to_string(
        partial: 'clone_modal',
        locals: { view_mode: params[:view_mode] },
        formats: :html
      )
    }
  end

  # POST: clone_experiment(id)
  def clone
    project = current_team.projects.find(move_experiment_param)
    return render_403 unless can_create_project_experiments?(project)

    service = Experiments::CopyExperimentAsTemplateService.call(experiment: @experiment,
                                                                project: project,
                                                                user: current_user)

    if service.succeed?
      flash[:success] = t('experiments.clone.success_flash',
                          experiment: @experiment.name)
      redirect_to canvas_experiment_path(service.cloned_experiment)
    else
      flash[:error] = t('experiments.clone.error_flash',
                        experiment: @experiment.name)
      redirect_to project_path(@experiment.project)
    end
  end

  # GET: move_modal_experiment_path(id)
  def move_modal
    @projects = @experiment.movable_projects(current_user)
    render json: {
      html: render_to_string(partial: 'move_modal', formats: :html)
    }
  end

  def search_tags
    tags = @experiment.project.tags.where.not(id: JSON.parse(params[:selected_tags]))
                      .where_attributes_like(:name, params[:query])
                      .select(:id, :name, :color)

    tags = tags.map do |tag|
      { value: tag.id, label: escape_input(tag.name), params: { color: escape_input(tag.color) } }
    end

    if params[:query].present? && tags.select { |tag| tag[:label] == params[:query] }.blank?
      tags << { value: 0, label: escape_input(params[:query]), params: { color: nil } }
    end
    render json: tags
  end

  # POST: move_experiment(id)
  def move
    service = Experiments::MoveToProjectService
              .call(experiment_id: @experiment.id,
                    project_id: move_experiment_param,
                    user_id: current_user.id)
    if service.succeed?
      flash[:success] = t('experiments.move.success_flash',
                          experiment: @experiment.name)
      status = :ok
      view_state = @experiment.current_view_state(current_user)
      view_type = view_state.state['my_modules']['view_type'] || 'canvas'
      path = view_mode_redirect_url(view_type)
    else
      message = "#{service.errors.values.join('. ')}."
      status = :unprocessable_entity
    end

    render json: { message: message, path: path }, status: status
  end

  def move_modules_modal
    @experiments = @experiment.project.experiments.active.where.not(id: @experiment)
                              .managable_by_user(current_user).order(name: :asc)
    render json: {
      html: render_to_string(partial: 'move_modules_modal', formats: :html)
    }
  end

  def move_modules
    modules_to_move = {}
    dst_experiment = @experiment.project.experiments.find(params[:to_experiment_id])
    return render_403 unless can_manage_experiment?(dst_experiment)

    @experiment.transaction do
      params[:my_module_ids].each do |id|
        my_module = @experiment.my_modules.find(id)
        return render_403 unless can_move_my_module?(my_module)

        modules_to_move[id] = dst_experiment.id
      end
      # Make sure that locks are acquired always in the same order
      if dst_experiment.id < @experiment.id
        dst_experiment.lock! && @experiment.lock!
      else
        @experiment.lock! && dst_experiment.lock!
      end
      @experiment.move_modules(modules_to_move, current_user)
      @experiment.workflowimg.purge

      render json: { message: t('experiments.table.modal_move_modules.success_flash',
                                experiment: escape_input(dst_experiment.name)) }
    rescue StandardError => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      render json: {
        message: t('experiments.table.modal_move_modules.error_flash', experiment: escape_input(dst_experiment.name))
      }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def module_archive
    @project = @experiment.project
    @my_modules = @experiment.archived_branch? ? @experiment.my_modules : @experiment.my_modules.archived
    @my_modules = @my_modules.with_granted_permissions(current_user, MyModulePermissions::READ_ARCHIVED)
                             .left_outer_joins(:designated_users, :task_comments)
                             .preload(:tags, outputs: :to)
                             .preload(:my_module_status, :my_module_group, user_assignments: %i(user user_role))
                             .select('COUNT(DISTINCT users.id) as designated_users_count')
                             .select('COUNT(DISTINCT comments.id) as task_comments_count')
                             .select('my_modules.*').group(:id)
  end

  def fetch_workflow_img
    unless @experiment.workflowimg_exists?
      Experiment.no_touching do
        Experiments::GenerateWorkflowImageService.call(experiment: @experiment)
      end
    end

    render json: {
      workflowimg: render_to_string(
        partial: 'projects/show/workflow_img',
        locals: { experiment: @experiment },
        formats: :html
      )
    }
  end

  def sidebar
    view_state = @experiment.current_view_state(current_user)
    view_mode = params[:view_mode].presence || 'active'
    default_sort = view_state.state.dig('my_modules', view_mode, 'sort') || 'atoz'
    my_modules = if @experiment.archived_branch?
                   @experiment.my_modules
                 elsif params[:view_mode] == 'archived'
                   @experiment.my_modules.archived
                 else
                   @experiment.my_modules.active
                 end

    my_modules = sort_my_modules(my_modules, params[:sort].presence || default_sort)
    render json: {
      html: render_to_string(
        partial: if params[:view_mode] == 'archived'
                    'shared/sidebar/archived_my_modules'
                  else
                    'shared/sidebar/my_modules'
                  end, locals: { experiment: @experiment, my_modules: my_modules }
      )
    }
  end

  def inventory_assigning_experiment_filter
    viewable_experiments = Experiment.viewable_by_user(current_user, current_team)
    assignable_my_modules = MyModule.repository_row_assignable_by_user(current_user)

    project = Project.viewable_by_user(current_user, current_team)
                     .joins(experiments: :my_modules)
                     .where(experiments: { id: viewable_experiments })
                     .where(my_modules: { id: assignable_my_modules })
                     .find_by(id: params[:project_id])

    return render_404 if project.blank?

    experiments = project.experiments
                         .active
                         .joins(:my_modules)
                         .where(experiments: { id: viewable_experiments })
                         .where(my_modules: { id: assignable_my_modules })
                         .distinct
                         .pluck(:id, :name)

    return render plain: [].to_json if experiments.blank?

    render json: experiments
  end

  def actions_dropdown
    if stale?([@experiment, @experiment.project])
      render json: {
        html: render_to_string(
          partial: 'projects/show/experiment_actions_dropdown',
          locals: { experiment: @experiment }
        )
      }
    end
  end

  def assigned_users_to_tasks
    users = current_team.users.where(id: @experiment.my_modules.joins(:user_my_modules).select(:user_id))
                        .search(false, params[:query]).map do |u|
      { value: u.id, label: escape_input(u.name), params: { avatar_url: avatar_path(u, :icon_small) } }
    end

    render json: users, status: :ok
  end

  def archive_my_modules
    my_modules = @experiment.my_modules.where(id: params[:my_modules])
    counter = 0
    my_modules.each do |my_module|
      next unless can_archive_my_module?(my_module)

      my_module.transaction do
        connect_my_modules_before_archive(my_module)

        my_module.archive!(current_user)
        log_my_module_activity(:archive_module, my_module)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end
    if counter.positive?
      render json: { message: t('experiments.table.archive_group.success_flash', number: counter) }
    else
      render json: { message: t('experiments.table.archive_group.error_flash') }, status: :unprocessable_entity
    end
  end

  def batch_clone_my_modules
    MyModule.transaction do
      @my_modules =
        @experiment.my_modules
                   .readable_by_user(current_user)
                   .where(id: params[:my_module_ids])

      @my_modules.find_each do |my_module|
        new_my_module = my_module.dup
        new_my_module.my_module_status = MyModuleStatus.first
        new_my_module.update!(
          {
            provisioning_status: :in_progress,
            name: my_module.next_clone_name,
            created_by: current_user,
            due_date: nil,
            started_on: nil,
            state: 'uncompleted',
            completed_on: nil
          }.merge(new_my_module.get_new_position)
        )
        new_my_module.designated_users << current_user
        MyModules::CopyContentJob.perform_later(current_user.id, my_module.id, new_my_module.id)
      end
      @experiment.workflowimg.purge
    end

    render(
      json: {
        provisioning_status_urls: @my_modules.map { |m| provisioning_status_my_module_url(m) }
      }
    )
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::ExperimentsService.new(
          current_user,
          experiment_ids: params[:experiment_ids].split(',')
        ).actions
    }
  end

  private

  def load_experiment
    @experiment = Experiment.preload(user_assignments: %i(user user_role)).find_by(id: params[:id])
    render_404 unless @experiment
  end

  def load_project
    @project = Project.find_by(id: params[:project_id])
    render_404 unless @project
  end

  def experiment_params
    params.require(:experiment).permit(:name, :description, :archived)
  end

  def move_experiment_param
    params.require(:experiment).require(:project_id)
  end

  def view_type_params
    params.require(:experiment).require(:view_type)
  end

  def check_read_permissions
    current_team_switch(@experiment.project.team) if current_team != @experiment.project.team
    render_403 unless can_read_experiment?(@experiment) ||
                      (@experiment.archived? && can_read_archived_experiment?(@experiment))
  end

  def check_canvas_read_permissions
    render_403 unless can_read_experiment_canvas?(@experiment)
  end

  def check_create_permissions
    render_403 unless can_create_project_experiments?(@project)
  end

  def check_manage_permissions
    render_403 unless can_manage_experiment?(@experiment)
  end

  def check_update_permissions
    if experiment_params[:archived] == 'false'
      render_403 unless can_restore_experiment?(@experiment)
    else
      render_403 unless can_manage_experiment?(@experiment)
    end
  end

  def check_archive_permissions
    render_403 unless can_archive_experiment?(@experiment)
  end

  def check_clone_permissions
    render_403 unless can_clone_experiment?(@experiment)
  end

  def check_move_permissions
    render_403 unless can_move_experiment?(@experiment)
  end

  def set_inline_name_editing
    return unless can_manage_experiment?(@experiment)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'experiment',
      item_id: @experiment.id,
      field_to_udpate: 'name',
      path_to_update: experiment_path(@experiment)
    }
  end

  def experiment_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @experiment.description,
      subject: @experiment,
      title: t('notifications.experiment_annotation_title',
               experiment: @experiment.name,
               user: current_user.full_name),
      message: t('notifications.experiment_annotation_message_html',
                 project: link_to(@experiment.project.name,
                                  project_url(@experiment.project)),
                 experiment: link_to(@experiment.name,
                                     my_modules_experiment_url(@experiment)))
    )
  end

  def log_activity(type_of, experiment)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: experiment.team,
            project: experiment.project,
            subject: experiment,
            message_items: { experiment: experiment.id })
  end

  def log_my_module_activity(type_of, my_module)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: my_module.experiment.project.team,
            project: my_module.experiment.project,
            subject: my_module,
            message_items: { my_module: my_module.id })
  end

  def view_mode_redirect_url(view_type)
    if params[:view_mode] == 'archived'
      case view_type
      when 'canvas'
        module_archive_experiment_path(@experiment)
      else
        table_experiment_path(@experiment, view_mode: :archived)
      end
    else
      view_type == 'canvas' ? canvas_experiment_path(@experiment) : table_experiment_path(@experiment)
    end
  end

  def sort_my_modules(records, sort)
    case sort
    when 'due_first'
      records.order(:due_date, :name)
    when 'due_last'
      records.order(Arel.sql("COALESCE(due_date, DATE '2100-01-01') DESC"), :name)
    when 'atoz'
      records.order(:name)
    when 'ztoa'
      records.order(name: :desc)
    when 'archived_old'
      records.order(Arel.sql('COALESCE(my_modules.archived_on, my_modules.archived_on) ASC'))
    when 'archived_new'
      records.order(Arel.sql('COALESCE(my_modules.archived_on, my_modules.archived_on) DESC'))
    else
      records
    end
  end

  def connect_my_modules_before_archive(my_module)
    return if my_module.my_modules.empty? || my_module.my_module_antecessors.empty?

    my_module.my_modules.each do |destination_my_module|
      my_module.my_module_antecessors.each do |source_my_module|
        Connection.create!(input_id: destination_my_module.id, output_id: source_my_module.id)
      end
    end
  end

  def set_navigator
    @navigator = {
      url: tree_navigator_experiment_path(@experiment),
      archived: (action_name == 'module_archive' || params[:view_mode] == 'archived'),
      id: @experiment.code
    }
  end
end
