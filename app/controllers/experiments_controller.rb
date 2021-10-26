# frozen_string_literal: true

class ExperimentsController < ApplicationController
  include TeamsHelper
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  before_action :load_project, only: %i(new create archive_group restore_group)
  before_action :load_experiment, except: %i(new create archive_group restore_group)
  before_action :check_read_permissions, except: %i(edit archive clone move new create archive_group restore_group)
  before_action :check_canvas_read_permissions, only: %i(canvas)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(edit)
  before_action :check_update_permissions, only: %i(update)
  before_action :check_archive_permissions, only: :archive
  before_action :check_clone_permissions, only: %i(clone_modal clone)
  before_action :check_move_permissions, only: %i(move_modal move)
  before_action :set_inline_name_editing, only: %i(canvas module_archive)

  layout 'fluid'

  def new
    @experiment = Experiment.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'new_modal.html.erb'
          )
        }
      end
    end
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
      respond_to do |format|
        format.json do
          render json: { path: canvas_experiment_url(@experiment) }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: @experiment.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def show
    render json: {
      html: render_to_string(partial: 'experiments/details_modal.html.erb')
    }
  end

  def canvas
    redirect_to module_archive_experiment_path(@experiment) if @experiment.archived_branch?
    @project = @experiment.project
    @active_modules = @experiment.my_modules.active.order(:name).includes(:tags, :inputs, :outputs)
    current_team_switch(@project.team)
  end

  def edit
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'edit_modal.html.erb'
          )
        }
      end
    end
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
    experiments = @project.experiments.active.where(id: params[:experiments_ids])
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
    experiments = @project.experiments.archived.where(id: params[:experiments_ids])
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
    @projects = @experiment.projects_with_role_above_user(current_user)
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'clone_modal.html.erb'
          )
        }
      end
    end
  end

  # POST: clone_experiment(id)
  def clone
    service = Experiments::CopyExperimentAsTemplateService
              .call(experiment_id: @experiment.id,
                    project_id: move_experiment_param,
                    user_id: current_user.id)

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
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'move_modal.html.erb'
          )
        }
      end
    end
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
      path = canvas_experiment_url(@experiment)
      status = :ok
    else
      message = t('experiments.move.error_flash',
                  experiment: escape_input(@experiment.name))
      status = :unprocessable_entity
    end

    render json: { message: message, path: path }, status: status
  end

  def module_archive
    @my_modules = @experiment.archived_branch? ? @experiment.my_modules : @experiment.my_modules.archived
  end

  def fetch_workflow_img
    unless @experiment.workflowimg_exists?
      Experiment.no_touching do
        Experiments::GenerateWorkflowImageService.call(experiment: @experiment)
      end
    end

    respond_to do |format|
      format.json do
        render json: {
          workflowimg: render_to_string(
            partial: 'projects/show/workflow_img.html.erb',
            locals: { experiment: @experiment }
          )
        }
      end
    end
  end

  def sidebar
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'shared/sidebar/my_modules.html.erb', locals: { experiment: @experiment }
          )
        }
      end
    end
  end

  private

  def load_experiment
    @experiment = Experiment.find_by(id: params[:id])
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

  def check_read_permissions
    render_403 unless can_read_experiment?(@experiment) ||
                      @experiment.archived? && can_read_archived_experiment?(@experiment)
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
      title: t('notifications.experiment_annotation_title',
               experiment: @experiment.name,
               user: current_user.full_name),
      message: t('notifications.experiment_annotation_message_html',
                 project: link_to(@experiment.project.name,
                                  project_url(@experiment.project)),
                 experiment: link_to(@experiment.name,
                                     canvas_experiment_url(@experiment)))
    )
  end

  def log_activity(type_of, experiment)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: experiment.project.team,
            project: experiment.project,
            subject: experiment,
            message_items: { experiment: experiment.id })
  end
end
