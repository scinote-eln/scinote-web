class MyModulesController < ApplicationController
  include SampleActions
  include TeamsHelper
  include InputSanitizeHelper

  before_action :load_vars, only: [
    :show, :update, :destroy,
    :description, :due_date, :protocols, :results,
    :samples, :activities, :activities_tab,
    :assign_samples, :unassign_samples,
    :delete_samples, :toggle_task_state,
    :samples_index, :archive]
  before_action :load_vars_nested, only: [:new, :create]
  before_action :check_edit_permissions, only: [
    :update, :description, :due_date
  ]
  before_action :check_destroy_permissions, only: [:destroy]
  before_action :check_view_info_permissions, only: [:show]
  before_action :check_view_activities_permissions, only: [:activities, :activities_tab]
  before_action :check_view_protocols_permissions, only: [:protocols]
  before_action :check_view_results_permissions, only: [:results]
  before_action :check_view_samples_permissions, only: [:samples, :samples_index]
  before_action :check_view_archive_permissions, only: [:archive]
  before_action :check_assign_samples_permissions, only: [:assign_samples]
  before_action :check_unassign_samples_permissions, only: [:unassign_samples]

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

    if @my_module.archived_changed?(from: false, to: true)
      saved = @my_module.archive(current_user)
      if saved
        # Currently not in use
        Activity.create(
          type_of: :archive_module,
          project: @my_module.experiment.project,
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
        Activity.create(
          type_of: :restore_module,
          project: @my_module.experiment.project,
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
      if saved
        format.json {
          alerts = []
          if @my_module.is_overdue? && !@my_module.completed?
            alerts << 'alert-red'
          elsif @my_module.is_one_day_prior? && !@my_module.completed?
            alerts << 'alert-yellow'
          elsif @my_module.completed?
            alerts << 'alert-green'
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
          # Create activity
          str = if completed
                  'activities.complete_module'
                else
                  'activities.uncomplete_module'
                end
          message = t(str,
                      user: current_user.full_name,
                      module: @my_module.name)
          Activity.create(
            user: current_user,
            project: @project,
            my_module: @my_module,
            message: message,
            type_of: completed ? :complete_task : :uncomplete_task
          )

          if completed
            title = I18n.t('notifications.types.recent_changes')
            message = I18n.t('notifications.task_completed',
              user: current_user.name,
              module: @my_module.name,
              date: l(@my_module.completed_on, format: :full),
              project: @project.name,
              experiment: @my_module.experiment.name)

            notification = Notification.create(
              type_of: :recent_changes,
              title: title,
              message: sanitize_input(message),
              generator_user_id: current_user.id
            )
            if current_user.recent_notification
              UserNotification.create(
                notification: notification, user: current_user
              )
            end
          end

          # Create localized title for complete/uncomplete button
          button_title = if completed
                           t('my_modules.buttons.uncomplete')
                         else
                           t('my_modules.buttons.complete')
                         end

          format.json do
            render json: {
              new_title: button_title,
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

  private

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

  def my_module_params
    params.require(:my_module).permit(:name, :description, :due_date,
      :archived)
  end
end
