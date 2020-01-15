# frozen_string_literal: true

class ExperimentsController < ApplicationController
  include SampleActions
  include TeamsHelper
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include Rails.application.routes.url_helpers

  before_action :set_experiment,
                except: %i(new create)
  before_action :set_project,
                only: %i(new create samples_index samples module_archive
                         clone_modal move_modal delete_samples)
  before_action :load_projects_tree, only: %i(canvas samples module_archive)
  before_action :check_view_permissions,
                only: %i(canvas module_archive)
  before_action :check_manage_permissions, only: :edit
  before_action :check_archive_permissions, only: :archive
  before_action :check_clone_permissions, only: %i(clone_modal clone)
  before_action :check_move_permissions, only: %i(move_modal move)
  before_action :set_inline_name_editing, only: %i(canvas module_archive)

  layout 'fluid'.freeze

  # Action defined in SampleActions
  DELETE_SAMPLES = 'Delete'.freeze

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
      log_activity(:create_experiment)
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

  def canvas
    @project = @experiment.project
    @active_modules = @experiment.active_modules
                                 .includes(:tags, :inputs, :outputs)
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
    render_403 && return unless if experiment_params[:archived] == 'false'
                                  can_restore_experiment?(@experiment)
                                else
                                  can_manage_experiment?(@experiment)
                                end

    old_text = @experiment.description
    @experiment.update(experiment_params)
    @experiment.last_modified_by = current_user

    if @experiment.save
      experiment_annotation_notification(old_text)

      activity_type = if experiment_params[:archived] == 'false'
                        :restore_experiment
                      else
                        :edit_experiment
                      end
      log_activity(activity_type)

      respond_to do |format|
        format.json do
          render json: {}, status: :ok
        end
        format.html do
          flash[:success] = t('experiments.update.success_flash',
                          experiment: @experiment.name)
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
    @experiment.archived = true
    @experiment.archived_by = current_user
    @experiment.archived_on = DateTime.now
    if @experiment.save
      log_activity(:archive_experiment)
      flash[:success] = t('experiments.archive.success_flash',
                          experiment: @experiment.name)

      redirect_to project_path(@experiment.project)
    else
      flash[:alert] = t('experiments.archive.error_flash')
      redirect_back(fallback_location: root_path)
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
    @projects = @experiment.moveable_projects(current_user)
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
  end

  def samples
    @samples_index_link = samples_index_experiment_path(@experiment,
                                                        format: :json)
    @team = @experiment.project.team
  end

  def samples_index
    @team = @experiment.project.team

    respond_to do |format|
      format.html
      format.json do
        render json: ::SampleDatatable.new(view_context,
                                           @team,
                                           nil,
                                           nil,
                                           @experiment,
                                           current_user)
      end
    end
  end

  def updated_img
    if @experiment.workflowimg.attached? && !@experiment.workflowimg_exists?
      @experiment.workflowimg.purge
      @experiment.generate_workflow_img
    end
    respond_to do |format|
      format.json do
        if @experiment.workflowimg.attached?
          render json: {}, status: 200
        else
          render json: {}, status: 404
        end
      end
    end
  end

  def fetch_workflow_img
    respond_to do |format|
      format.json do
        render json: {
          workflowimg: render_to_string(
            partial: 'projects/show/workflow_img.html.erb'
          )
        }
      end
    end
  end

  private

  def set_experiment
    @experiment = Experiment.find_by_id(params[:id])
    render_404 unless @experiment
  end

  def set_project
    @project = Project.find_by_id(params[:project_id]) || @experiment.project
    render_404 unless @project
  end

  def experiment_params
    params.require(:experiment).permit(:name, :description, :archived)
  end

  def move_experiment_param
    params.require(:experiment).require(:project_id)
  end

  def load_projects_tree
    # Switch to correct team
    current_team_switch(@experiment.project.team) unless @experiment.project.nil?
    @projects_tree = current_user.projects_tree(current_team, nil)
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@experiment)
  end

  def check_manage_permissions
    render_403 unless can_manage_experiment?(@experiment)
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

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: @experiment.project.team,
            project: @experiment.project,
            subject: @experiment,
            message_items: { experiment: @experiment.id })
  end
end
