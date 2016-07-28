class ExperimentsController < ApplicationController
  include PermissionHelper
  before_action :set_experiment, except: [:new, :create]
  before_action :set_project, only: [:new, :create]

  # except parameter could be used but it is not working.
  layout :choose_layout

  def new
    @experiment = Experiment.new
    respond_to do |format|
      format.json  {
        render json:{
          html: render_to_string( {
            partial: "new_modal.html.erb"
          })
        }
      }
    end
  end

  def create
    @experiment = Experiment.new(experiment_params)
    @experiment.created_by = current_user
    @experiment.last_modified_by = current_user
    @experiment.project = @project
    if @experiment.save
      @project.experiments << @experiment
      flash[:success] = t('experiments.create.success_flash', experiment: @experiment.name)
      # have to change to experiments path
      redirect_to root_path
    else
      flash[:danger]  = t('experiments.create.error_flash')
      render :new
    end
  end

  def canvas
    @project = @experiment.project
  end

  def update
    @experiment.update_attributes(experiment_params)
    @experiment.last_modified_by = current_user
    if @experiment.save
      flash[:success] = t('experiments.update.success_flash', experiment: @experiment.name)
      # have to change to experiments path
      redirect_to root_path
    else
      flash[:danger] = t('experiments.update.error_flash')
      render :edit
    end
  end

  def archive_experiment
    @experiment.archived = true
    @experiment.archived_by = current_user
    @experiment.archived_on = DateTime.now
    if @experiment.save
      flash[:success] = t('experiments.archive.success_flash', experiment: @experiment.name)
      # have to change to experiments path
      redirect_to root_path
    else
      flash[:danger] = t('experiments.archive.error_flash')
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
    params.require(:experiment).permit(:name, :description)
  end

  def choose_layout
    action_name.in?(['index', 'archive']) ? 'main' : 'fluid'
  end
end
