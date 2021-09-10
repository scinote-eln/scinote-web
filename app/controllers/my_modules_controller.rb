class MyModulesController < ApplicationController
  include TeamsHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  before_action :load_vars, except: %i(restore_group)
  before_action :check_archive_permissions, only: %i(update)
  before_action :check_manage_permissions, only: %i(description due_date update_description update_protocol_description)
  before_action :check_view_permissions, except: %i(update update_description update_protocol_description restore_group)
  before_action :check_update_state_permissions, only: :update_state
  before_action :set_inline_name_editing, only: %i(protocols results activities archive)
  before_action :load_experiment_my_modules, only: %i(protocols results activities archive)

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

  def status_state
    respond_to do |format|
      format.json do
        render json: { status_changing: @my_module.status_changing? }
      end
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
    else
      render_403 && return unless can_manage_module?(@my_module)

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
      if saved
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
              locals: { my_module: @my_module, my_module_editable: true }
            ),
            due_date_label: render_to_string(
              partial: 'my_modules/due_date_label.html.erb',
              locals: { my_module: @my_module, my_module_editable: true }
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
    old_description = @my_module.description
    respond_to do |format|
      format.json do
        if @my_module.update(description: params.require(:my_module)[:description])
          log_activity(:change_module_description)
          TinyMceAsset.update_images(@my_module, params[:tiny_mce_images], current_user)
          my_module_annotation_notification(old_description)
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
    old_description = protocol.description
    return render_404 unless protocol

    respond_to do |format|
      format.json do
        if protocol.update(description: params.require(:protocol)[:description])
          log_activity(:protocol_description_in_task_edited)
          TinyMceAsset.update_images(protocol, params[:tiny_mce_images], current_user)
          protocol_annotation_notification(old_description)
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

    @results_order = params[:order] || 'new'

    @results = @my_module.archived_branch? ? @my_module.results : @my_module.results.active
    @results = @results.page(params[:page]).per(Constants::RESULTS_PER_PAGE_LIMIT)

    @results = case @results_order
               when 'old' then @results.order(updated_at: :asc)
               when 'atoz' then @results.order(name: :asc)
               when 'ztoa' then @results.order(name: :desc)
               else @results.order(updated_at: :desc)
               end
  end

  def archive
    @archived_results = @my_module.archived_results
    current_team_switch(@my_module.experiment.project.team)
  end

  def restore_group
    experiment = Experiment.find(params[:id])
    return render_403 unless can_read_experiment?(experiment)

    my_modules = experiment.my_modules.archived.where(id: params[:my_modules_ids])
    counter = 0
    my_modules.each do |my_module|
      next unless can_restore_module?(my_module)

      my_module.transaction do
        my_module.restore!(current_user)
        log_activity(:restore_module, my_module)
        counter += 1
      rescue StandardError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end
    if counter == my_modules.size
      flash[:success] = t('my_modules.restore_group.success_flash_html', number: counter)
    elsif counter.positive?
      flash[:warning] = t('my_modules.restore_group.partial_success_flash_html', number: counter)
    else
      flash[:error] = t('my_modules.restore_group.error_flash')
    end
    redirect_to module_archive_experiment_path(experiment)
  end

  def update_state
    old_status_id = @my_module.my_module_status_id
    if @my_module.update(my_module_status_id: update_status_params[:status_id])
      log_activity(:change_status_on_task_flow, @my_module, my_module_status_old: old_status_id,
                   my_module_status_new: @my_module.my_module_status.id)

      return redirect_to protocols_my_module_path(@my_module)
    else
      render json: { errors: @my_module.errors.messages.values.flatten.join('\n') }, status: :unprocessable_entity
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

  def load_experiment_my_modules
    @experiment_my_modules = @my_module.experiment.my_modules.where(archived: @my_module.archived?).order(:name)
  end

  def check_manage_permissions
    render_403 && return unless can_manage_module?(@my_module)
  end

  def check_archive_permissions
    return render_403 if my_module_params[:archived] == 'true' && !can_archive_module?(@my_module)
  end

  def check_view_permissions
    render_403 unless can_read_protocol_in_module?(@my_module.protocol)
  end

  def check_update_state_permissions
    return render_403 unless can_change_my_module_flow_status?(@my_module)

    render_404 unless @my_module.my_module_status
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

  def update_status_params
    params.require(:my_module).permit(:status_id)
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

  def my_module_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @my_module.description,
      title: t('notifications.my_module_description_annotation_title',
               my_module: @my_module.name,
               user: current_user.full_name),
      message: t('notifications.my_module_description_annotation_message_html',
                 project: link_to(@my_module.experiment.project.name, project_url(@my_module.experiment.project)),
                 experiment: link_to(@my_module.experiment.name, canvas_experiment_url(@my_module.experiment)),
                 my_module: link_to(@my_module.name, protocols_my_module_url(@my_module)))
    )
  end

  def protocol_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @my_module.protocol.description,
      title: t('notifications.my_module_protocol_annotation_title',
               my_module: @my_module.name,
               user: current_user.full_name),
      message: t('notifications.my_module_protocol_annotation_message_html',
                 project: link_to(@my_module.experiment.project.name, project_url(@my_module.experiment.project)),
                 experiment: link_to(@my_module.experiment.name, canvas_experiment_url(@my_module.experiment)),
                 my_module: link_to(@my_module.name, protocols_my_module_url(@my_module)))
    )
  end
end
