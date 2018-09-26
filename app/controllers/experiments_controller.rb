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
      Activity.create(
        type_of: :create_experiment,
        project: @experiment.project,
        experiment: @experiment,
        user: current_user,
        message: I18n.t(
          'activities.create_experiment',
          user: current_user.full_name,
          experiment: @experiment.name
        )
      )
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
    @experiment.update_attributes(experiment_params)
    @experiment.last_modified_by = current_user

    if @experiment.save

      experiment_annotation_notification(old_text)
      Activity.create(
        type_of: :edit_experiment,
        project: @experiment.project,
        experiment: @experiment,
        user: current_user,
        message: I18n.t(
          'activities.edit_experiment',
          user: current_user.full_name,
          experiment: @experiment.name
        )
      )
      @experiment.touch(:workflowimg_updated_at)
      flash[:success] = t('experiments.update.success_flash',
                          experiment: @experiment.name)

      respond_to do |format|
        format.json do
          render json: {}, status: :ok
        end
        format.html do
          redirect_to project_path(@experiment.project)
        end
      end
    else
      flash[:alert] = t('experiments.update.error_flash')
      respond_to do |format|
        format.json do
          render json: @experiment.errors, status: :unprocessable_entity
        end
        format.html do
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
      Activity.create(
        type_of: :archive_experiment,
        project: @experiment.project,
        experiment: @experiment,
        user: current_user,
        message: I18n.t(
          'activities.archive_experiment',
          user: current_user.full_name,
          experiment: @experiment.name
        )
      )
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
    project = Project.find_by_id(params[:experiment].try(:[], :project_id))

    # Try to clone the experiment
    success = true
    if @experiment.projects_with_role_above_user(current_user).include?(project)
      cloned_experiment = @experiment.deep_clone_to_project(current_user,
                                                            project)
      success = cloned_experiment.valid?
      # Create workflow image
      cloned_experiment.delay.generate_workflow_img if success
    else
      success = false
    end

    if success
      Activity.create(
        type_of: :clone_experiment,
        project: project,
        experiment: @experiment,
        user: current_user,
        message: I18n.t(
          'activities.clone_experiment',
          user: current_user.full_name,
          experiment_new: cloned_experiment.name,
          experiment_original: @experiment.name
        )
      )

      flash[:success] = t('experiments.clone.success_flash',
                          experiment: @experiment.name)
      redirect_to canvas_experiment_path(cloned_experiment)
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
    project = Project.find_by_id(params[:experiment].try(:[], :project_id))
    old_project = @experiment.project

    # Try to move the experiment
    success = true
    if @experiment.moveable_projects(current_user).include?(project)
      success = @experiment.move_to_project(project)
    else
      success = false
    end

    if success
      Activity.create(
        type_of: :move_experiment,
        project: project,
        experiment: @experiment,
        user: current_user,
        message: I18n.t(
          'activities.move_experiment',
          user: current_user.full_name,
          experiment: @experiment.name,
          project_new: project.name,
          project_original: old_project.name
        )
      )

      flash[:success] = t('experiments.move.success_flash',
                          experiment: @experiment.name)
      respond_to do |format|
        format.json do
          render json: { path: canvas_experiment_url(@experiment) }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: { message: t('experiments.move.error_flash',
                                    experiment:
                                      escape_input(@experiment.name)) },
                                    status: :unprocessable_entity
        end
      end
    end
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
    respond_to do |format|
      format.json do
        if @experiment.workflowimg_updated_at.to_i >=
           params[:timestamp].to_time.to_i
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
end
