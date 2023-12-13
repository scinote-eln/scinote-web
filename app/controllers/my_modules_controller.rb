class MyModulesController < ApplicationController
  include TeamsHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include MyModulesHelper
  include Breadcrumbs

  before_action :load_vars, except: %i(restore_group create new save_table_state
                                       inventory_assigning_my_module_filter actions_toolbar)
  before_action :load_experiment, only: %i(create new)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_archive_permissions, only: %i(update)
  before_action :check_manage_permissions, only: %i(
    description due_date update_description update_protocol_description update_protocol
  )
  before_action :check_read_permissions, except: %i(create new update update_description
                                                    inventory_assigning_my_module_filter
                                                    update_protocol_description restore_group
                                                    save_table_state actions_toolbar)
  before_action :check_update_state_permissions, only: :update_state
  before_action :set_inline_name_editing, only: %i(protocols activities archive)
  before_action :load_experiment_my_modules, only: %i(protocols activities archive)
  before_action :set_breadcrumbs_items, only: %i(protocols activities archive)
  before_action :set_navigator, only: %i(protocols activities archive)

  layout 'fluid'.freeze

  def new
    @my_module = @experiment.my_modules.new
    assigned_users = User.where(id: @experiment.user_assignments.select(:user_id))

    render json: {
      html: render_to_string(
        partial: 'my_modules/modals/new_modal', locals: { view_mode: params[:view_mode],
                                                                   users: assigned_users }
      )
    }
  end

  def create
    @my_module = @experiment.my_modules.new(my_module_params)
    new_pos = @my_module.get_new_position
    @my_module.assign_attributes(
      created_by: current_user,
      last_modified_by: current_user,
      x: new_pos[:x],
      y: new_pos[:y]
    )
    @my_module.transaction do
      if my_module_tags_params[:tag_ids].present?
        @my_module.tags << @experiment.project.tags.where(id: JSON.parse(my_module_tags_params[:tag_ids]))
      end
      if my_module_designated_users_params[:user_ids].present? && can_designate_users_to_new_task?(@experiment)
        @my_module.designated_users << @experiment.users.where(id: my_module_designated_users_params[:user_ids])
      elsif !can_designate_users_to_new_task?(@experiment)
        @my_module.designated_users << current_user
      end
      @my_module.save!
      Activities::CreateActivityService.call(
        activity_type: :create_module,
        owner: current_user,
        team: @my_module.experiment.project.team,
        project: @my_module.experiment.project,
        subject: @my_module,
        message_items: { my_module: @my_module.id }
      )
      log_user_designation_activity
      redirect_to canvas_experiment_path(@experiment) if params[:my_module][:view_mode] == 'canvas'
    rescue ActiveRecord::RecordInvalid
      render json: @my_module.errors, status: :unprocessable_entity
      raise ActiveRecord::Rollback
    end
  end

  def show
    render json: {
      html: render_to_string(partial: 'show')
    }
  end

  # Description modal window in full-zoom canvas
  def description
    render json: {
      html: render_to_string(partial: 'description'),
      title: t('my_modules.description.title', module: escape_input(@my_module.name))
    }
  end

  def save_table_state
    current_user.settings.update(visible_my_module_table_columns: params[:columns])
    current_user.save!
  end

  def status_state
    if @my_module.last_transition_error && @my_module.last_transition_error['type'] == 'repository_snapshot'
      flash[:repository_snapshot_error] = @my_module.last_transition_error
    end

    render json: { status_changing: @my_module.status_changing? }
  end

  def canvas_dropdown_menu
    @experiment_managable = can_manage_experiment?(@experiment)
    @group_my_modules = @my_module.my_module_group&.my_modules&.preload(user_assignments: %i(user user_role))
    render json: {
      html: render_to_string({ partial: 'canvas/edit/my_module_dropdown_menu',
                               locals: { my_module: @my_module } })
    }
  end

  def activities
    params[:subjects] = {
      MyModule: [@my_module.id]
    }
    @activity_types = Activity.activity_types_list

    activities = ActivitiesService.load_activities(current_user, current_team, activity_filters)

    @grouped_activities = activities.group_by do |activity|
      Time.zone.at(activity.created_at).to_date.to_s
    end

    @next_page = activities.next_page

    respond_to do |format|
      format.json do
        render json: {
          activities_html: render_to_string(
            partial: 'global_activities/activity_list',
            formats: :html
          ),
          next_page: @next_page
        }
      end
      format.html
    end
  end

  # Different controller for showing activities inside tab
  def activities_tab
    @activities = @my_module.last_activities(1, @per_page)

    render json: {
      html: render_to_string(partial: 'activities', formats: :html)
    }
  end

  # Due date modal window in full-zoom canvas
  def due_date
    render json: {
      html: render_to_string(partial: 'due_date', formats: :html),
      title: t('.due_date.title', module: escape_input(@my_module.name))
    }
  end

  def update
    @my_module.assign_attributes(my_module_params)
    @my_module.last_modified_by = current_user
    name_changed = @my_module.name_changed?
    description_changed = @my_module.description_changed?
    start_date_changes = @my_module.changes[:started_on]
    due_date_changes = @my_module.changes[:due_date]

    render_403 && return if @my_module.completed_on_changed? && !can_complete_my_module?(@my_module)

    render_403 && return if description_changed && !can_update_my_module_description?(@my_module)

    render_403 && return if start_date_changes.present? && !can_update_my_module_start_date?(@my_module)

    render_403 && return if due_date_changes.present? && !can_update_my_module_start_date?(@my_module)

    if @my_module.archived_changed?(from: false, to: true)
      saved = @my_module.archive(current_user)
    else
      render_403 && return unless can_manage_my_module?(@my_module)

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
    if saved
      alerts = []
      alerts << 'alert-green' if @my_module.completed?
      unless @my_module.completed?
        alerts << 'alert-red' if @my_module.is_overdue?
        alerts << 'alert-yellow' if @my_module.is_one_day_prior?
      end
      render json: {
        status: :ok,
        start_date_label: render_to_string(
          partial: 'my_modules/start_date_label',
          formats: :html,
          locals: { my_module: @my_module, start_date_editable: true }
        ),
        due_date_label: render_to_string(
          partial: 'my_modules/due_date_label',
          formats: :html,
          locals: { my_module: @my_module, due_date_editable: true }
        ),
        card_due_date_label: render_to_string(
          partial: 'my_modules/card_due_date_label',
          formats: :html,
          locals: { my_module: @my_module }
        ),
        table_due_date_label: {
          html: render_to_string(partial: 'experiments/table_due_date_label',
                                 formats: :html,
                                 locals: { my_module: @my_module, user: current_user }),
          due_status: my_module_due_status(@my_module)
        },
        module_header_due_date: render_to_string(
          partial: 'my_modules/module_header_due_date',
          formats: :html,
          locals: { my_module: @my_module }
        ),
        description_label: render_to_string(
          partial: 'my_modules/description_label',
          formats: :html,
          locals: { my_module: @my_module }
        ),
        alerts: alerts
      }
    else
      render json: @my_module.errors, status: :unprocessable_entity
    end
  end

  def update_description
    render_403 && return unless can_update_my_module_description?(@my_module)

    old_description = @my_module.description
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

  def update_protocol_description
    protocol = @my_module.protocol
    old_description = protocol.description
    return render_404 unless protocol

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

  def protocols
    @protocol = @my_module.protocol
    @assigned_repositories = @my_module.live_and_snapshot_repositories_list
  end

  def protocol
    render json: @my_module.protocol, serializer: ProtocolSerializer, user: current_user
  end

  def update_protocol
    protocol = @my_module.protocol
    old_description = protocol.description

    ActiveRecord::Base.transaction do
      protocol.update!(protocol_params)
      log_activity(:protocol_name_in_task_edited) if protocol.saved_change_to_name?
      log_activity(:protocol_description_in_task_edited) if protocol.saved_change_to_description?
      TinyMceAsset.update_images(protocol, params[:tiny_mce_images], current_user)
      protocol_annotation_notification(old_description)
    end

    render json: protocol, serializer: ProtocolSerializer, user: current_user
  rescue ActiveRecord::RecordInvalid
    render json: protocol.errors, status: :unprocessable_entity
  end

  def archive
    @archived_results = @my_module.archived_results
  end

  def restore_group
    experiment = Experiment.find(params[:id])
    return render_403 unless can_read_experiment?(experiment)

    my_modules = experiment.my_modules.archived.where(id: params[:my_modules_ids])
    counter = 0
    my_modules.each do |my_module|
      next unless can_restore_my_module?(my_module)

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

    if params[:view] == 'table'
      redirect_to table_experiment_path(experiment, view_mode: :archived)
    else
      redirect_to module_archive_experiment_path(experiment)
    end
  end

  def update_state
    old_status_id = @my_module.my_module_status_id
    if @my_module.update(my_module_status_id: update_status_params[:status_id])
      log_activity(:change_status_on_task_flow, @my_module, my_module_status_old: old_status_id,
                   my_module_status_new: @my_module.my_module_status.id)

      render json: { status: :changed }
    else
      render json: { errors: @my_module.errors.messages.values.flatten.join('\n') }, status: :unprocessable_entity
    end
  end

  def permissions
    if stale?(@my_module)
      render json: {
        editable: can_manage_my_module?(@my_module),
        moveable: can_move_my_module?(@my_module),
        archivable: can_archive_my_module?(@my_module),
        restorable: can_restore_my_module?(@my_module)
      }
    end
  end

  def actions_dropdown
    if stale?(@my_module)
      render json: {
        html: render_to_string(
          partial: 'experiments/table_row_actions',
          locals: { my_module: @my_module }
        )
      }
    end
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::MyModulesService.new(
          current_user,
          my_module_ids: params[:my_module_ids].split(',')
        ).actions
    }
  end

  def provisioning_status
    render json: { provisioning_status: @my_module.provisioning_status }
  end

  def inventory_assigning_my_module_filter
    viewable_experiments = Experiment.viewable_by_user(current_user, current_team)
    assignable_my_modules = MyModule.repository_row_assignable_by_user(current_user)

    experiment = Experiment.viewable_by_user(current_user, current_team)
                           .joins(:my_modules)
                           .where(experiments: { id: viewable_experiments })
                           .where(my_modules: { id: assignable_my_modules })
                           .find_by(id: params[:experiment_id])

    return render_404 if experiment.blank?

    my_modules = experiment.my_modules
                           .where(my_modules: { id: assignable_my_modules })
                           .pluck(:id, :name)

    return render plain: [].to_json if my_modules.blank?

    render json: my_modules
  end

  private

  def load_vars
    @my_module = MyModule.preload(user_assignments: %i(user user_role)).find_by(id: params[:id])
    if @my_module
      @experiment = @my_module.experiment
      @project = @my_module.experiment.project if @experiment
    else
      render_404
    end
  end

  def load_experiment
    @experiment = Experiment.preload(user_assignments: %i(user user_role)).find_by(id: params[:id])
    render_404 unless @experiment
  end

  def load_experiment_my_modules
    @experiment_my_modules = if @my_module.experiment.archived_branch?
                               @my_module.experiment.my_modules.order(:name)
                             else
                               @my_module.experiment.my_modules.where(archived: @my_module.archived?).order(:name)
                             end
  end

  def check_create_permissions
    render_403 && return unless can_create_experiment_tasks?(@experiment)
  end

  def check_manage_permissions
    render_403 && return unless can_manage_my_module?(@my_module)
  end

  def check_archive_permissions
    return render_403 if my_module_params[:archived] == 'true' && !can_archive_my_module?(@my_module)
  end

  def check_read_permissions
    current_team_switch(@project.team) if current_team != @project.team
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_update_state_permissions
    return render_403 unless can_update_my_module_status?(@my_module)

    render_404 unless @my_module.my_module_status
  end

  def set_inline_name_editing
    return unless can_manage_my_module?(@my_module)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'my_module',
      item_id: @my_module.id,
      field_to_udpate: 'name',
      path_to_update: my_module_path(@my_module)
    }
  end

  def my_module_params
    permitted_params = params.require(:my_module).permit(:name, :description, :started_on, :due_date, :archived)

    if permitted_params[:started_on].present?
      permitted_params[:started_on] =
        Time.zone.strptime(permitted_params[:started_on], '%Y/%m/%d %H:%M')
    end
    if permitted_params[:due_date].present?
      permitted_params[:due_date] =
        Time.zone.strptime(permitted_params[:due_date], '%Y/%m/%d %H:%M')
    end

    permitted_params
  end

  def my_module_tags_params
    params.require(:my_module).permit(:tag_ids)
  end

  def my_module_designated_users_params
    params.require(:my_module).permit(user_ids: [])
  end

  def protocol_params
    params.require(:protocol).permit(:name, :description)
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

  def log_user_designation_activity
    users = User.where.not(id: current_user.id).where(id: params[:my_module][:user_ids])

    users.each do |user|
      log_activity(:designate_user_to_my_module, @my_module, { user_target: user.id })
    end
  end

  def log_activity(type_of, my_module = nil, message_items = {})
    my_module ||= @my_module
    message_items = { my_module: my_module.id }.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: my_module.team,
            project: my_module.project,
            subject: my_module,
            message_items: message_items)
  end

  def activity_filters
    params.permit(
      :page, :from_date, :to_date, types: [], users: [], subjects: {}
    )
  end

  def my_module_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @my_module.description,
      subject: @my_module,
      title: t('notifications.my_module_description_annotation_title',
               my_module: @my_module.name,
               user: current_user.full_name),
      message: t('notifications.my_module_description_annotation_message_html',
                 project: link_to(@my_module.experiment.project.name, project_url(@my_module.experiment.project)),
                 experiment: link_to(@my_module.experiment.name, my_modules_experiment_url(@my_module.experiment)),
                 my_module: link_to(@my_module.name, protocols_my_module_url(@my_module)))
    )
  end

  def protocol_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: @my_module.protocol.description,
      subject: @my_module,
      title: t('notifications.my_module_protocol_annotation_title',
               my_module: @my_module.name,
               user: current_user.full_name),
      message: t('notifications.my_module_protocol_annotation_message_html',
                 project: link_to(@my_module.experiment.project.name, project_url(@my_module.experiment.project)),
                 experiment: link_to(@my_module.experiment.name, my_modules_experiment_url(@my_module.experiment)),
                 my_module: link_to(@my_module.name, protocols_my_module_url(@my_module)))
    )
  end

  def set_navigator
    @navigator = {
      url: tree_navigator_my_module_path(@my_module),
      archived: params[:view_mode] == 'archived',
      id: @my_module.code
    }
  end
end
