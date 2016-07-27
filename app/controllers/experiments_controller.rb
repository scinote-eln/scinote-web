class ExperimentsController < ApplicationController
  include PermissionHelper
  before_action :set_experiment, except: [:new, :create]
  before_action :set_project, only: [:new, :create]
  before_action :check_view_permissions
  before_action :check_edit_permissions, only: :edit
  before_action :check_create_permissions, only: [:new, :create]
  before_action :check_archive_permissions, only: :archive_experiment

  def new
    @experiment = Experiment.new
  end

  def create
    @experiment = Experiment.new(experiment_params)
    @experiment.created_by = current_user
    # @experiment.last_modified_by = current_user
    if @experiment.save
      @project.experiments << @experiment
      flash[:success] = t('experiments.create.success_flash', name: @experiment.name)
      respond_to do |format|
        format.json{}
      end
    else
      flash[:danger]  = t('experiments.create.error_flash', name: @experiment.name)
      render :new
    end
  end

  def edit
  end

  def update
    @experiment.update_attributes(experiment_params)
    @experiment.last_modified_by = current_user
    if @experiment.save
      flash[:success] = t('experiments.update.success_flash', name: @experiment.name)
      respond_to do |format|
        format.json{}
      end
    else
      flash[:danger] = t('experiments.create.error_flash', name: @experiment.name)
      render :edit
    end
  end

  def archive_experiment
    @experiment.archived = true
    @experiment.archived_by = current_user
    @experiment.archived_on = DateTime.now
    if @experiment.save
      flash[:success] = t('experiments.archive.success_flash', name: @experiment.name)
      respond_to do |format|
        format.json{}
      end
    else
      flash[:danger] = t('experiments.archive.error_flash', name: @experiment.name)
    end
  end

  private

  def set_experiment
    @experiment = Experiment.find_by_id(params[:id])
  end

  def set_project
    @project = Project.find_by_id(params[:project_id])
  end

  def experiment_params
    params.require(:experiment).permit(:name, :description, :archived)
  end

  def check_view_permissions
    render_403 unless can_view_project(@project)
  end

  def check_edit_permissions
    render_403 unless can_edit_project(@project)
  end

  def check_create_permissions
    render_403 unless can_create_project(@project.organization)
  end

  def check_archive_permissions
    render_403 unless can_archive_project(@project)
  end
end
