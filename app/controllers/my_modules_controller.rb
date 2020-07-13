class MyModulesController < ApplicationController
  include SampleActions
  include TeamsHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  before_action :load_vars
  before_action :load_projects_tree, only: %i(protocols results activities archive)
  before_action :check_manage_permissions_archive, only: %i(update)
  before_action :check_manage_permissions, only: %i(description due_date update_description update_protocol_description)
  before_action :check_view_permissions, except: %i(update update_description update_protocol_description
                                                    toggle_task_state)
  before_action :check_complete_module_permission, only: %i(complete_my_module toggle_task_state)
  before_action :set_inline_name_editing, only: %i(protocols results activities archive)

  layout 'fluid'.freeze

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
    params[:subjects] = {
      MyModule: [@my_module.id]
    }
    @activity_types = Activity.activity_types_list
    @user_list = User.where(id: UserTeam.where(team: current_user.teams).select(:user_id))
                     .distinct
                     .pluck(:full_name, :id)
    activities = ActivitiesService.load_activities(current_user, current_team, activity_filters)

    @grouped_activities = activities.group_by do |activity|
      Time.zone.at(activity.created_at).to_date.to_s
    end

    @next_page = activities.next_page
    @starting_timestamp = activities.first&.created_at.to_i

    respond_to do |format|
      format.json do
        render json: {
          activities_html: render_to_string(
            partial: 'global_activities/activity_list.html.erb'
          ),
          next_page: @next_page,
          starting_timestamp: @starting_timestamp
        }
      end
      format.html do
      end
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
    name_changed = @my_module.name_changed?
    description_changed = @my_module.description_changed?
    start_date_changes = @my_module.changes[:started_on]
    due_date_changes = @my_module.changes[:due_date]

    if @my_module.archived_changed?(from: false, to: true)
      saved = @my_module.archive(current_user)
    elsif @my_module.archived_changed?(from: true, to: false)
      saved = @my_module.restore(current_user)
      if saved
        restored = true
        log_activity(:restore_module)
      end
    else
      saved = @my_module.save
      if saved
        if description_changed
          log_activity(:change_module_description)
          TinyMceAsset.update_images(@my_module, params[:tiny_mce_images], current_user)
        end

        log_activity(:rename_task) if name_changed
        log_start_date_change_activity(start_date_changes) if start_date_changes.present?
        log_due_date_change_activity(due_date_changes) if due_date_changes.present?
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
        format.json do
          alerts = []
          alerts << 'alert-green' if @my_module.completed?
          unless @my_module.completed?
            alerts << 'alert-red' if @my_module.is_overdue?
            alerts << 'alert-yellow' if @my_module.is_one_day_prior?
          end
          render json: {
            status: :ok,
            start_date_label: render_to_string(
              partial: 'my_modules/start_date_label.html.erb',
              locals: { my_module: @my_module }
            ),
            due_date_label: render_to_string(
              partial: 'my_modules/due_date_label.html.erb',
              locals: { my_module: @my_module }
            ),
            card_due_date_label: render_to_string(
              partial: 'my_modules/card_due_date_label.html.erb',
              locals: { my_module: @my_module }
            ),
            module_header_due_date: render_to_string(
              partial: 'my_modules/module_header_due_date.html.erb',
              locals: { my_module: @my_module }
            ),
            description_label: render_to_string(
              partial: 'my_modules/description_label.html.erb',
              locals: { my_module: @my_module }
            ),
            alerts: alerts
          }
        end
      else
        format.json do
          render json: @my_module.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def update_description
    respond_to do |format|
      format.json do
        if @my_module.update(description: params.require(:my_module)[:description])
          log_activity(:change_module_description)
          TinyMceAsset.update_images(@my_module, params[:tiny_mce_images], current_user)
          render json: {
            html: custom_auto_link(
              @my_module.tinymce_render(:description),
              simple_format: false,
              tags: %w(img),
              team: current_team
            )
          }
        else
          render json: @my_module.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def update_protocol_description
    protocol = @my_module.protocol
    return render_404 unless protocol
    respond_to do |format|
      format.json do
        if protocol.update(description: params.require(:protocol)[:description])
          log_activity(:protocol_description_in_task_edited)
          TinyMceAsset.update_images(protocol, params[:tiny_mce_images], current_user)
          render json: {
            html: custom_auto_link(
              protocol.tinymce_render(:description),
              simple_format: false,
              tags: %w(img),
              team: current_team
            )
          }
        else
          render json: protocol.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def protocols
    @protocol = @my_module.protocol
    @assigned_repositories = @my_module.live_and_snapshot_repositories_list
    current_team_switch(@protocol.team)
  end

  def results
    current_team_switch(@my_module
                                .experiment
                                .project
                                .team)
  end

  def archive
    @archived_results = @my_module.archived_results
    current_team_switch(@my_module
                                .experiment
                                .project
                                .team)
  end

  # Complete/uncomplete task
  def toggle_task_state
    respond_to do |format|
      @my_module.completed? ? @my_module.uncompleted! : @my_module.completed!
      task_completion_activity

      # Render new button HTML
      new_btn_partial = if @my_module.completed?
                          'my_modules/state_button_uncomplete.html.erb'
                        else
                          'my_modules/state_button_complete.html.erb'
                        end

      format.json do
        render json: {
          new_btn: render_to_string(partial: new_btn_partial),
          completed: @my_module.completed?,
          module_header_due_date: render_to_string(
            partial: 'my_modules/module_header_due_date.html.erb',
            locals: { my_module: @my_module }
          ),
          module_state_label: render_to_string(
            partial: 'my_modules/module_state_label.html.erb',
            locals: { my_module: @my_module }
          )
        }
      end
    end
  end

  def complete_my_module
    respond_to do |format|
      if @my_module.uncompleted? && @my_module.check_completness_status
        @my_module.completed!
        task_completion_activity
        format.json do
          render json: {
            task_button_title: t('my_modules.buttons.uncomplete'),
            module_header_due_date: render_to_string(
              partial: 'my_modules/module_header_due_date.html.erb',
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
    log_activity(completed ? :complete_task : :uncomplete_task)
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

  def load_projects_tree
    # Switch to correct team
    current_team_switch(@project.team) unless @project.nil?
    @projects_tree = current_user.projects_tree(current_team, 'atoz')
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

  def check_complete_module_permission
    render_403 unless can_complete_module?(@my_module)
  end

  def set_inline_name_editing
    return unless can_manage_module?(@my_module)
    @inline_editable_title_config = {
      name: 'title',
      params_group: 'my_module',
      item_id: @my_module.id,
      field_to_udpate: 'name',
      path_to_update: my_module_path(@my_module)
    }
  end

  def my_module_params
    update_params = params.require(:my_module).permit(:name, :description, :started_on, :due_date, :archived)

    if update_params[:started_on].present?
      update_params[:started_on] =
        Time.zone.strptime(update_params[:started_on], I18n.backend.date_format.dup.gsub(/%-/, '%') + ' %H:%M')
    end
    if update_params[:due_date].present?
      update_params[:due_date] =
        Time.zone.strptime(update_params[:due_date], I18n.backend.date_format.dup.gsub(/%-/, '%') + ' %H:%M')
    end

    update_params
  end

  def log_start_date_change_activity(start_date_changes)
    type_of = if start_date_changes[0].nil?     # set started_on
                message_items = { my_module_started_on: @my_module.started_on }
                :set_task_start_date
              elsif start_date_changes[1].nil?  # remove started_on
                message_items = { my_module_started_on: start_date_changes[0] }
                :remove_task_start_date
              else                              # change started_on
                message_items = { my_module_started_on: @my_module.started_on }
                :change_task_start_date
              end
    log_activity(type_of, @my_module, message_items)
  end

  def log_due_date_change_activity(due_date_changes)
    type_of = if due_date_changes[0].nil?     # set due_date
                message_items = { my_module_duedate: @my_module.due_date }
                :set_task_due_date
              elsif due_date_changes[1].nil?  # remove due_date
                message_items = { my_module_duedate: due_date_changes[0] }
                :remove_task_due_date
              else                            # change due_date
                message_items = { my_module_duedate: @my_module.due_date }
                :change_task_due_date
              end
    log_activity(type_of, @my_module, message_items)
  end

  def log_activity(type_of, my_module = nil, message_items = {})
    my_module ||= @my_module
    message_items = { my_module: my_module.id }.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: my_module.experiment.project.team,
            project: my_module.experiment.project,
            subject: my_module,
            message_items: message_items)
  end

  def activity_filters
    params.permit(
      :page, :starting_timestamp, :from_date, :to_date, types: [], users: [], subjects: {}
    )
  end
end
