# frozen_string_literal: true

class ExperimentsController < ApplicationController
  include TeamsHelper
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers
  include Breadcrumbs

  before_action :load_project, only: %i(index create archive_group restore_group move)
  before_action :load_experiment, except: %i(create archive_group restore_group
                                             inventory_assigning_experiment_filter actions_toolbar index move)
  before_action :load_experiments, only: :move
  before_action :check_read_permissions, except: %i(index edit archive clone move new
                                                    create archive_group restore_group
                                                    inventory_assigning_experiment_filter actions_toolbar)
  before_action :check_canvas_read_permissions, only: %i(canvas)
  before_action :check_create_permissions, only: %i(create move)
  before_action :check_manage_permissions, only: :batch_clone_my_modules
  before_action :check_update_permissions, only: :update
  before_action :check_archive_permissions, only: :archive
  before_action :check_clone_permissions, only: %i(clone_modal clone)
  before_action :set_inline_name_editing, only: %i(index canvas module_archive)
  before_action :set_breadcrumbs_items, only: %i(index canvas module_archive)
  before_action :set_navigator, only: %i(index canvas module_archive)

  layout 'fluid'

  def index
    respond_to do |format|
      format.json do
        experiments = Lists::ExperimentsService.new(@project.experiments,
                                                    params.merge(project: @project),
                                                    user: current_user).call
        render json: experiments, each_serializer: Lists::ExperimentSerializer, user: current_user,
               meta: pagination_dict(experiments)
      end
      format.html do
        render 'experiments/index'
      end
    end
  end

  def assigned_users
    render json: User.where(id: @experiment.user_assignments.select(:user_id)),
           each_serializer: UserSerializer,
           user: current_user
  end

  def create
    @experiment = Experiment.new(experiment_params)
    @experiment.created_by = current_user
    @experiment.last_modified_by = current_user
    @experiment.project = @project
    if @experiment.save
      experiment_annotation_notification
      log_activity(:create_experiment, @experiment)
      flash[:success] = t('.success_flash',
                          experiment: @experiment.name)

      render json: { path: my_modules_experiment_url(@experiment) }, status: :ok
    else
      render json: @experiment.errors, status: :unprocessable_entity
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

    save_view_type('canvas')
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

      render json: { message: t('experiments.update.success_flash', experiment: @experiment.name) }, status: :ok
    else
      render json: { message: @experiment.errors.full_messages }, status: :unprocessable_entity
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

  def projects_to_clone
    projects = @experiment.project.team.projects.active
                          .with_user_permission(current_user, ProjectPermissions::EXPERIMENTS_CREATE)
                          .where('trim_html_tags(projects.name) ILIKE ?',
                                 "%#{ActiveRecord::Base.sanitize_sql_like(params['query'])}%")
                          .map { |p| [p.id, p.name] }
    render json: { data: projects }, status: :ok
  end

  def projects_to_move
    projects = @experiment.movable_projects(current_user)
                          .where('trim_html_tags(projects.name) ILIKE ?',
                                 "%#{ActiveRecord::Base.sanitize_sql_like(params['query'])}%")
                          .map { |p| [p.id, p.name] }
    render json: { data: projects }, status: :ok
  end

  def experiments_to_move
    experiments = @experiment.project.experiments.active.where.not(id: @experiment)
                             .managable_by_user(current_user).order(name: :asc).map { |e| [e.id, e.name] }
    render json: { data: experiments }, status: :ok
  end

  # POST: clone_experiment(id)
  def clone
    @project = current_team.projects.find(move_experiment_param)
    return render_403 unless can_create_project_experiments?(@project)

    service = Experiments::CopyExperimentAsTemplateService.call(experiment: @experiment,
                                                                project: @project,
                                                                user: current_user)

    if service.succeed?
      flash[:success] = t('experiments.clone.success_flash',
                          experiment: @experiment.name)
      render json: { url: canvas_experiment_path(service.cloned_experiment) }
    else
      render json: {
        message: t('experiments.clone.error_flash',
        experiment: @experiment.name)
      }, status: :unprocessable_entity
    end
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

  # POST: move_experiments(ids)
  def move
    return render_403 unless @experiments.all? { |e| can_move_experiment?(e) }

    @project.transaction do
      @experiments.each do |experiment|
        service = Experiments::MoveToProjectService
                  .call(experiment_id: experiment.id,
                        project_id: params[:project_id],
                        user_id: current_user.id)
        raise StandardError unless service.succeed?
      end

      flash[:success] = t('experiments.table.move_success_flash', project: escape_input(@project.name))
      render json: { message: t('experiments.table.move_success_flash',
                                project: escape_input(@project.name)), path: project_path(@project) }
    rescue StandardError => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      render json: {
        message: t('experiments.table.move_error_flash', project: escape_input(@project.name))
      }, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  rescue ActiveRecord::RecordNotFound
    render_404
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
      workflowimg_url: rails_blob_path(@experiment.workflowimg, only_path: true),
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
                         .order(:name)
                         .distinct
                         .pluck(:id, :name)

    return render plain: [].to_json if experiments.blank?

    render json: experiments
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
          experiment_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
  end

  private

  def load_experiment
    @experiment = Experiment.preload(user_assignments: %i(user user_role)).find_by(id: params[:id])
    render_404 unless @experiment
  end

  def load_experiments
    @experiments = Experiment.preload(user_assignments: %i(user user_role)).where(id: params[:ids])
    render_404 unless @experiments
  end

  def load_project
    @project = Project.find_by(id: params[:project_id])

    render_404 unless @project
    render_403 unless can_read_project?(@project)
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

  def save_view_type(view_type)
    view_state = @experiment.current_view_state(current_user)
    view_state.state['my_modules']['view_type'] = view_type
    view_state.save!
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

  def set_inline_name_editing
    if @experiment
      return unless can_manage_experiment?(@experiment)

      @inline_editable_title_config = {
        name: 'title',
        params_group: 'experiment',
        item_id: @experiment.id,
        field_to_udpate: 'name',
        path_to_update: experiment_path(@experiment)
      }
    else
      return unless can_manage_project?(@project)

      @inline_editable_title_config = {
        name: 'title',
        params_group: 'project',
        item_id: @project.id,
        field_to_udpate: 'name',
        path_to_update: project_path(@project)
      }
    end
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
        my_modules_path(experiment_id: @experiment, view_mode: :archived)
      end
    else
      view_type == 'canvas' ? canvas_experiment_path(@experiment) : my_modules_path(experiment_id: @experiment)
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
    @navigator = if @experiment
                   {
                     url: tree_navigator_experiment_path(@experiment),
                     archived: (action_name == 'module_archive' || params[:view_mode] == 'archived'),
                     id: @experiment.code
                   }
                 else
                   {
                     url: tree_navigator_project_path(@project),
                     archived: (action_name == 'index' && params[:view_mode] == 'archived'),
                     id: @project.code
                   }
                 end
  end
end
