class MyModulesController < ApplicationController
  include SampleActions
  include TeamsHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  before_action :load_vars,
                only: %i(show update destroy description due_date protocols
                         results samples activities activities_tab
                         assign_samples unassign_samples delete_samples
                         toggle_task_state samples_index archive
                         complete_my_module repository repository_index
                         assign_repository_records unassign_repository_records
                         unassign_repository_records_modal
                         assign_repository_records_modal)
  before_action :load_vars_nested, only: %i(new create)
  before_action :load_repository, only: %i(assign_repository_records
                                           unassign_repository_records
                                           unassign_repository_records_modal
                                           assign_repository_records_modal
                                           repository_index)
  before_action :load_projects_tree, only: %i(protocols results activities
                                              samples repository archive)
  before_action :check_manage_permissions_archive, only: %i(update destroy)
  before_action :check_manage_permissions, only: %i(description due_date)
  before_action :check_view_permissions, only:
    %i(show activities activities_tab protocols results samples samples_index
       archive)
  before_action :check_complete_module_permission, only: :complete_my_module
  before_action :check_assign_repository_records_permissions,
                only: %i(unassign_repository_records_modal
                         assign_repository_records_modal
                         assign_repository_records
                         unassign_repository_records
                         assign_samples
                         unassign_samples)

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

    @activities = @my_module.last_activities(@last_activity_id, @per_page + 1)
    @more_activities_url = ""

    @overflown = @activities.length > @per_page

    @activities = @my_module.last_activities(@last_activity_id, @per_page)

    if @activities.count > 0
      @more_activities_url =
        activities_my_module_path(@my_module, from: @activities.last.id)
    end

    respond_to do |format|
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
      format.html
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
    render_403 if @repository.nil? || !can_read_team?(@repository.team)
    current_team_switch(@repository.team)
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
      @my_module.downstream_modules.each do |my_module|
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
      @my_module.downstream_modules.each do |my_module|
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

  # AJAX actions
  def repository_index
    @draw = params[:draw].to_i
    per_page = params[:length] == '-1' ? 100 : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    records = RepositoryDatatableService.new(@repository,
                                             params,
                                             current_user,
                                             @my_module)
    @assigned_rows = records.assigned_rows
    @repository_row_count = records.repository_rows.length
    @columns_mappings = records.mappings
    @repository_rows = records.repository_rows.page(page).per(per_page)
    render 'repository_rows/index.json'
  end

  # Submit actions
  def assign_repository_records
    if params[:selected_rows].present? && params[:repository_id].present?
      records_names = []
      downstream = ActiveModel::Type::Boolean.new.cast(params[:downstream])

      RepositoryRow
        .where(id: params[:selected_rows],
               repository_id: params[:repository_id])
        .find_each do |record|
        unless @my_module.repository_rows.include?(record)
          record.last_modified_by = current_user
          record.save

          MyModuleRepositoryRow.create!(
            my_module: @my_module,
            repository_row: record,
            assigned_by: current_user
          )
          records_names << record.name
        end

        next unless downstream
        @my_module.downstream_modules.each do |my_module|
          next if my_module.repository_rows.include?(record)
          MyModuleRepositoryRow.create!(
            my_module: my_module,
            repository_row: record,
            assigned_by: current_user
          )
          records_names << record.name
        end
      end

      if records_names.any?
        records_names.uniq!
        Activity.create(
          type_of: :assign_repository_record,
          project: @project,
          experiment: @experiment,
          my_module: @my_module,
          user: current_user,
          message: I18n.t('activities.assign_repository_records',
                          user: current_user.full_name,
                          task: @my_module.name,
                          repository: @repository.name,
                          records: records_names.join(', ')
                        )
        )
        flash = I18n.t('repositories.assigned_records_flash',
                       records: records_names.join(', '))
        flash = I18n.t('repositories.assigned_records_downstream_flash',
                       records: records_names.join(', ')) if downstream
        respond_to do |format|
          format.json { render json: { flash: flash }, status: :ok }
        end
      else
        respond_to do |format|
          format.json do
            render json: {
              flash: t('repositories.no_records_assigned_flash')
            }, status: :bad_request
          end
        end
      end
    end
  end

  def unassign_repository_records
    if params[:selected_rows].present? && params[:repository_id].present?
      downstream = ActiveModel::Type::Boolean.new.cast(params[:downstream])

      records = RepositoryRow.assigned_on_my_module(params[:selected_rows],
                                                    @my_module)

      @my_module.repository_rows.destroy(records & @my_module.repository_rows)

      if downstream
        @my_module.downstream_modules.each do |my_module|
          assigned_records = RepositoryRow.assigned_on_my_module(
            params[:selected_rows],
            my_module
          )
          my_module.repository_rows.destroy(
            assigned_records & my_module.repository_rows
          )
          assigned_records.update_all(last_modified_by_id: current_user.id)
        end
      end

      # update last last_modified_by
      records.update_all(last_modified_by_id: current_user.id)

      if records.any?
        Activity.create(
          type_of: :unassign_repository_record,
          project: @project,
          experiment: @experiment,
          my_module: @my_module,
          user: current_user,
          message: I18n.t(
            'activities.unassign_repository_records',
            user: current_user.full_name,
            task: @my_module.name,
            repository: @repository.name,
            records: records.map(&:name).join(', ')
          )
        )
        flash = I18n.t('repositories.unassigned_records_flash',
                       records: records.map(&:name).join(', '))
        respond_to do |format|
          format.json { render json: { flash: flash }, status: :ok }
        end
      else
        respond_to do |format|
          format.json do
            render json: {
              flash: t('repositories.no_records_unassigned_flash')
            }, status: :bad_request
          end
        end
      end
    end
  end

  def unassign_repository_records_modal
    selected_rows = params[:selected_rows]
    modal = render_to_string(
      partial: 'my_modules/modals/unassign_repository_records_modal.html.erb',
      locals: { my_module: @my_module,
                repository: @repository,
                selected_rows: selected_rows }
    )
    render json: { html: modal }, status: :ok
  end

  def assign_repository_records_modal
    selected_rows = params[:selected_rows]
    modal = render_to_string(
      partial: 'my_modules/modals/assign_repository_records_modal.html.erb',
      locals: { my_module: @my_module,
                repository: @repository,
                selected_rows: selected_rows }
    )
    render json: { html: modal }, status: :ok
  end

  # Complete/uncomplete task
  def toggle_task_state
    respond_to do |format|
      if can_complete_module?(@my_module)
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
    start_work_on_next_task_notification
  end

  def start_work_on_next_task_notification
    if @my_module.completed?
      title = t('notifications.start_work_on_next_task',
                user: current_user.full_name,
                module: @my_module.name)
      message = t('notifications.start_work_on_next_task_message',
                  project: link_to(@project.name, project_url(@project)),
                  experiment: link_to(@experiment.name,
                                      canvas_experiment_url(@experiment)),
                  my_module: link_to(@my_module.name,
                                     protocols_my_module_url(@my_module)))
      notification = Notification.create(
        type_of: :recent_changes,
        title: sanitize_input(title, %w(strong a)),
        message: sanitize_input(message, %w(strong a)),
        generator_user_id: current_user.id
      )
      # create notification for all users on the next modules in the workflow
      @my_module.my_modules.map(&:users).flatten.uniq.each do |target_user|
        next if target_user == current_user || !target_user.recent_notification
        UserNotification.create(notification: notification, user: target_user)
      end
    end
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

  def load_repository
    @repository = Repository.find_by_id(params[:repository_id])
    render_404 unless @repository
    render_403 unless can_read_team?(@repository.team)
  end

  def load_projects_tree
    # Switch to correct team
    current_team_switch(@project.team) unless @project.nil?
    @projects_tree = current_user.projects_tree(current_team, nil)
  end

  def check_manage_permissions
    render_403 && return unless can_manage_module?(@my_module)
  end

  def check_manage_permissions_archive
    render_403 && return unless if my_module_params[:archived] == 'false'
                                  can_restore_module?(@my_module)
                                else
                                  can_manage_module?(@my_module)
                                end
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@my_module.experiment)
  end

  def check_assign_repository_records_permissions
    render_403 unless module_page? &&
                      can_assign_repository_rows_to_module?(@my_module)
  end

  def check_assign_samples_permissions
    render_403 unless module_page? &&
                      can_assign_sample_to_module?(@my_module)
  end

  def check_complete_module_permission
    render_403 unless can_complete_module?(@my_module)
  end

  def my_module_params
    params.require(:my_module).permit(:name, :description, :due_date,
                                      :archived)
  end
end
