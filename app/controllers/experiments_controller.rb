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
  before_action :check_experiment_clone_permissions,
                only: [:clone_modal, :clone]

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

      redirect_to project_path(@experiment.project)
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

  # GET: clone_modal_experiment_path(id)
  def clone_modal
    @projects = projects_with_role_above_user
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
    project = Project.find_by_id(params[:experiment][:project_id])

    # Try to clone the experiment
    success = true
    if projects_with_role_above_user.include?(project)
      cloned_experiment = @experiment.deep_clone_to_project(current_user,
                                                            project)
      success = cloned_experiment.valid?
    else
      success = false
    end

    if success
      Activity.create(
        type_of: :clone_experiment,
        project: project,
        user: current_user,
        message: I18n.t(
          "activities.clone_experiment",
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

  def check_experiment_clone_permissions
    render_403 unless can_clone_experiment(@experiment)
  end

  def choose_layout
    action_name.in?(%w(index archive)) ? 'main' : 'fluid'
  end

  # Get projects where user is either owner or user in the same organization
  # as this experiment
  def projects_with_role_above_user
    organization = @experiment.project.organization
    current_user.user_projects
                .where(project:
                        Project.where(organization: organization)
                              .where(archived: false))
                .where('role < 2')
                .map(&:project)
  end
end
