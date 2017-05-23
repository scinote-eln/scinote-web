class MyModulesController < ApplicationController
  include SampleActions
  include TeamsHelper
  include InputSanitizeHelper

  before_action :load_vars,
                only: %I[show update destroy description due_date protocols
                         results samples activities activities_tab
                         assign_samples unassign_samples delete_samples
                         toggle_task_state samples_index archive
                         complete_my_module repository]
  before_action :load_vars_nested, only: %I[new create]
  before_action :check_edit_permissions,
                only: %I[update description due_date]
  before_action :check_destroy_permissions, only: :destroy
  before_action :check_view_info_permissions, only: :show
  before_action :check_view_activities_permissions,
                only: %I[activities activities_tab]
  before_action :check_view_protocols_permissions, only: :protocols
  before_action :check_view_results_permissions, only: :results
  before_action :check_view_samples_permissions,
                only: %I[samples samples_index]
  before_action :check_view_archive_permissions, only: :archive
  before_action :check_assign_samples_permissions, only: :assign_samples
  before_action :check_unassign_samples_permissions, only: :unassign_samples
  before_action :check_complete_my_module_perimission, only: :complete_my_module

  layout 'fluid'.freeze

  # Define submit actions constants (used in routing)
  ASSIGN_SAMPLES = 'Assign'.freeze
  UNASSIGN_SAMPLES = 'Unassign'.freeze

  # Action defined in SampleActions
  DELETE_SAMPLES = 'Delete'.freeze

  def show
    respond_to do |format|
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "show.html.erb"
          })
        }
      }
    end
  end

  # Description modal window in full-zoom canvas
  def description
    respond_to do |format|
      format.html
      format.json {
        render json: {
          html: render_to_string({
            partial: "description.html.erb"
          }),
          title: t('my_modules.description.title',
                   module: escape_input(@my_module.name))
        }
      }
    end
  end

  def activities
    @last_activity_id = params[:from].to_i || 0
    @per_page = 10

    @activities = @my_module.last_activities(@last_activity_id, @per_page +1 )
    @more_activities_url = ""

    @overflown = @activities.length > @per_page

    @activities = @my_module.last_activities(@last_activity_id, @per_page)

    if @activities.count > 0
      @more_activities_url = url_for(
        controller: 'my_modules',
        action: 'activities',
        format: :json,
        from: @activities.last.id)
    end

    respond_to do |format|
      format.html
      format.json {
        # 'activites' partial includes header and form for adding older
        # activities. 'list' partial is used for showing more activities.
        partial = "activities.html.erb"
        if @activities.last.id > 0
          partial = "my_modules/activities/list_activities.html.erb"
        end
        render :json => {
          :per_page => @per_page,
          :results_number => @activities.length,
          :more_url => @more_activities_url,
          :html => render_to_string({
            :partial => partial
          })
        }
      }
    end
  end

  # Different controller for showing activities inside tab
  def activities_tab
    @activities = @my_module.last_activities(1, @per_page)

    respond_to do |format|
      format.html
      format.json {
        render :json => {
          :html => render_to_string({
            :partial => "activities.html.erb"
          })
        }
      }
    end
  end

  # Due date modal window in full-zoom canvas
  def due_date
    respond_to do |format|
      format.html
      format.json {
        render json: {
          html: render_to_string({
            partial: "due_date.html.erb"
          }),
          title: t('my_modules.due_date.title',
                   module: escape_input(@my_module.name))
        }
      }
    end
  end

  def update
    @my_module.assign_attributes(my_module_params)
    @my_module.last_modified_by = current_user

    description_changed = @my_module.description_changed?
    restored = false

    if @my_module.archived_changed?(from: false, to: true)
      saved = @my_module.archive(current_user)
      if saved
        # Currently not in use
        Activity.create(
          type_of: :archive_module,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          user: current_user,
          message: t(
            'activities.archive_module',
            user: current_user.full_name,
            module: @my_module.name
          )
        )
      end
    elsif @my_module.archived_changed?(from: true, to: false)
      saved = @my_module.restore(current_user)
      if saved
        restored = true
        Activity.create(
          type_of: :restore_module,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          user: current_user,
          message: t(
            'activities.restore_module',
            user: current_user.full_name,
            module: @my_module.name
          )
        )
      end
    else
      saved = @my_module.save

      if saved and description_changed then
        Activity.create(
          type_of: :change_module_description,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          user: current_user,
          message: t(
            "activities.change_module_description",
            user: current_user.full_name,
            module: @my_module.name
          )
        )
      end
    end

    respond_to do |format|
      if restored
        format.html do
          flash[:success] = t(
            'my_modules.module_archive.restored_flash',
            module: @my_module.name
          )
          redirect_to module_archive_experiment_path(@my_module.experiment)
        end
      elsif saved
        format.json {
          alerts = []
          alerts << 'alert-green' if @my_module.completed?
          unless @my_module.completed?
            alerts << 'alert-red' if @my_module.is_overdue?
            alerts << 'alert-yellow' if @my_module.is_one_day_prior?
          end
          render json: {
            status: :ok,
            due_date_label: render_to_string(
              partial: "my_modules/due_date_label.html.erb",
              locals: { my_module: @my_module }
            ),
            module_header_due_date_label: render_to_string(
              partial: "my_modules/module_header_due_date_label.html.erb",
              locals: { my_module: @my_module }
            ),
            description_label: render_to_string(
              partial: "my_modules/description_label.html.erb",
              locals: { my_module: @my_module }
            ),
            alerts: alerts
          }
        }
      else
        format.json {
          render json: @my_module.errors,
            status: :unprocessable_entity
        }
      end
    end
  end

  def protocols
    @protocol = @my_module.protocol
    current_team_switch(@protocol.team)
  end

  def results
    current_team_switch(@my_module
                                .experiment
                                .project
                                .team)
  end

  def samples
    @samples_index_link = samples_index_my_module_path(@my_module, format: :json)
    @team = @my_module.experiment.project.team
  end

  def repository
    @repository = Repository.find_by_id(params[:repository_id])
    render_403 if @repository.nil? || !can_view_repository(@repository)
  end

  def archive
    @archived_results = @my_module.archived_results
    current_team_switch(@my_module
                                .experiment
                                .project
                                .team)
  end

  # Submit actions
  def assign_samples
    if params[:sample_ids].present?
      samples = []

      params[:sample_ids].each do |id|
        sample = Sample.find_by_id(id)
        sample.last_modified_by = current_user
        sample.save

        if sample
          samples << sample
        end
      end

      task_names = []
      new_samples = []
      @my_module.get_downstream_modules.each do |my_module|
        new_samples = samples.select { |el| my_module.samples.exclude?(el) }
        my_module.samples.push(*new_samples)
        task_names << my_module.name
      end
      if new_samples.any?
        Activity.create(
          type_of: :assign_sample,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          user: current_user,
          message: I18n.t(
            'activities.assign_sample',
            user: current_user.full_name,
            tasks: task_names.join(', '),
            samples: new_samples.map(&:name).join(', ')
          )
        )
      end
    end
    redirect_to samples_my_module_path(@my_module)
  end

  def unassign_samples
    if params[:sample_ids].present?
      samples = []

      params[:sample_ids].each do |id|
        sample = Sample.find_by_id(id)
        sample.last_modified_by = current_user
        sample.save

        if sample && @my_module.samples.include?(sample)
          samples << sample
        end
      end

      task_names = []
      @my_module.get_downstream_modules.each do |my_module|
        task_names << my_module.name
        my_module.samples.destroy(samples & my_module.samples)
      end
      if samples.any?
        Activity.create(
          type_of: :unassign_sample,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          user: current_user,
          message: I18n.t(
            'activities.unassign_sample',
            user: current_user.full_name,
            tasks: task_names.join(', '),
            samples: samples.map(&:name).join(', ')
          )
        )
      end
    end
    redirect_to samples_my_module_path(@my_module)
  end

  # AJAX actions
  def samples_index
    @team = @my_module.experiment.project.team

    respond_to do |format|
      format.html
      format.json do
        render json: ::SampleDatatable.new(view_context,
                                           @team,
                                           nil,
                                           @my_module,
                                           nil,
                                           current_user)
      end
    end
  end

  # Complete/uncomplete task
  def toggle_task_state
    respond_to do |format|
      if can_complete_module(@my_module)
        @my_module.completed? ? @my_module.uncomplete : @my_module.complete
        completed = @my_module.completed?
        if @my_module.save
          task_completion_activity

          # Render new button HTML
          if completed
            new_btn_partial = 'my_modules/state_button_uncomplete.html.erb'
          else
            new_btn_partial = 'my_modules/state_button_complete.html.erb'
          end

          format.json do
            render json: {
              new_btn: render_to_string(partial: new_btn_partial),
              completed: completed,
              module_header_due_date_label: render_to_string(
                partial: 'my_modules/module_header_due_date_label.html.erb',
                locals: { my_module: @my_module }
              ),
              module_state_label: render_to_string(
                partial: 'my_modules/module_state_label.html.erb',
                locals: { my_module: @my_module }
              )
            }
          end
        else
          format.json { render json: {}, status: :unprocessable_entity }
        end
      else
        format.json { render json: {}, status: :unauthorized }
      end
    end
  end

  def complete_my_module
    respond_to do |format|
      if @my_module.uncompleted? && @my_module.check_completness_status
        @my_module.complete
        @my_module.save
        task_completion_activity
        format.json do
            render json: {
              task_button_title: t('my_modules.buttons.uncomplete'),
              module_header_due_date_label: render_to_string(
                partial: 'my_modules/module_header_due_date_label.html.erb',
                locals: { my_module: @my_module }
              ),
              module_state_label: render_to_string(
                partial: 'my_modules/module_state_label.html.erb',
                locals: { my_module: @my_module }
              )
            }, status: :ok
          end
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  private

  def task_completion_activity
    completed = @my_module.completed?
    str = 'activities.uncomplete_module'
    str = 'activities.complete_module' if completed
    message = t(str,
                user: current_user.full_name,
                module: @my_module.name)
    Activity.create(
      user: current_user,
      project: @project,
      experiment: @experiment,
      my_module: @my_module,
      message: message,
      type_of: completed ? :complete_task : :uncomplete_task
    )
  end

  def load_vars
    @my_module = MyModule.find_by_id(params[:id])
    if @my_module
      @experiment = @my_module.experiment
      @project = @my_module.experiment.project if @experiment
    else
      render_404
    end
  end

  def check_edit_permissions
    unless can_edit_module(@my_module)
      render_403
    end
  end

  def check_destroy_permissions
    unless can_archive_module(@my_module)
      render_403
    end
  end

  def check_view_info_permissions
    unless can_view_module_info(@my_module)
      render_403
    end
  end

  def check_view_activities_permissions
    unless can_view_module_activities(@my_module)
      render_403
    end
  end

  def check_view_protocols_permissions
    unless can_view_module_protocols(@my_module)
      render_403
    end
  end

  def check_view_results_permissions
    unless can_view_results_in_module(@my_module)
      render_403
    end
  end

  def check_view_samples_permissions
    unless can_view_module_samples(@my_module)
      render_403
    end
  end

  def check_view_archive_permissions
    unless can_view_module_archive(@my_module)
      render_403
    end
  end

  def check_assign_samples_permissions
    unless can_add_samples_to_module(@my_module)
      render_403
    end
  end

  def check_unassign_samples_permissions
    unless can_delete_samples_from_module(@my_module)
      render_403
    end
  end

  def check_complete_my_module_perimission
    render_403 unless can_complete_module(@my_module)
  end

  def my_module_params
    params.require(:my_module).permit(:name, :description, :due_date,
      :archived)
  end
end
