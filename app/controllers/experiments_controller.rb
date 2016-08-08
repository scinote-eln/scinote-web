class ExperimentsController < ApplicationController
  include PermissionHelper
  before_action :set_experiment,
                except: [:new, :create]
  before_action :set_project,
                only: [:new, :create, :samples_index,
                       :samples, :module_archive]
  before_action :check_view_permissions,
                only: [:canvas, :module_archive]
  before_action :check_module_archive_permissions,
                only: [:module_archive]

  # except parameter could be used but it is not working.
  layout :choose_layout

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
      flash[:success] = t('experiments.create.success_flash',
                          experiment: @experiment.name)
      redirect_to project_path(@project)
    else
      flash[:alert] = t('experiments.create.error_flash')
      redirect_to :back
    end
  end

  def canvas
    @project = @experiment.project
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
    @experiment.update_attributes(experiment_params)
    @experiment.last_modified_by = current_user
    if @experiment.save
      flash[:success] = t('experiments.update.success_flash',
                          experiment: @experiment.name)
      redirect_to canvas_experiment_path(@experiment)
    else
      flash[:alert] = t('experiments.update.error_flash')
      redirect_to :back
    end
  end

  def archive
    @experiment.archived = true
    @experiment.archived_by = current_user
    @experiment.archived_on = DateTime.now
    if @experiment.save
      flash[:success] = t('experiments.archive.success_flash',
                          experiment: @experiment.name)

      redirect_to project_path(@experiment.project)
    else
      flash[:alert] = t('experiments.archive.error_flash')
      redirect_to :back
    end
  end

  def module_archive
  end

  def samples
    @samples_index_link = samples_index_experiment_path(@experiment,
                                                        format: :json)
    @organization = @experiment.project.organization
  end

  def samples_index
    @organization = @experiment.project.organization

    respond_to do |format|
      format.html
      format.json do
        render json: ::SampleDatatable.new(view_context,
                                           @organization,
                                           nil,
                                           nil,
                                           @experiment)
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

  def check_view_permissions
    render_403 unless can_view_experiment(@experiment)
  end

  def check_module_archive_permissions
    render_403 unless can_view_experiment_archive(@experiment)
  end

  def choose_layout
    action_name.in?(%w(index archive)) ? 'main' : 'fluid'
  end
end
