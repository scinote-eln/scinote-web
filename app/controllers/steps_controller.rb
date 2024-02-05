class StepsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include StepsActions
  include MarvinJsActions

  before_action :load_vars, only: %i(update destroy show toggle_step_state update_view_state
                                     update_asset_view_mode elements
                                     attachments upload_attachment duplicate)
  before_action :load_vars_nested, only: %i(create index reorder)
  before_action :convert_table_contents_to_utf8, only: %i(create update)

  before_action :check_protocol_manage_permissions, only: %i(reorder)
  before_action :check_view_permissions, only: %i(show index attachments elements)
  before_action :check_create_permissions, only: %i(create)
  before_action :check_manage_permissions, only: %i(update destroy
                                                    update_view_state update_asset_view_mode upload_attachment)
  before_action :check_complete_and_checkbox_permissions, only: %i(toggle_step_state)

  def index
    render json: @protocol.steps.in_order, each_serializer: StepSerializer, user: current_user
  end

  def elements
    render json: @step.step_orderable_elements.order(:position),
           each_serializer: StepOrderableElementSerializer,
           user: current_user
  end

  def attachments
    render json: @step.assets,
           each_serializer: AssetSerializer,
           user: current_user
  end

  def upload_attachment
    @step.transaction do
      @asset = @step.assets.create!(
        created_by: current_user,
        last_modified_by: current_user,
        team: @protocol.team,
        view_mode: @step.assets_view_mode
      )
      @asset.file.attach(params[:signed_blob_id])
      @asset.post_process_file

      default_message_items = {
        step: @step.id,
        step_position: { id: @step.id,
                         value_for: 'position_plus_one' }
      }

      if @protocol.in_module?
        log_activity(
          :task_step_file_added,
          @my_module.experiment.project,
          {
            file: @asset.file_name,
            my_module: @my_module.id
          }.merge(default_message_items)
        )
      else
        log_activity(
          :protocol_step_file_added,
          nil,
          {
            file: @asset.file_name,
            protocol: @protocol.id
          }.merge(default_message_items)
        )
      end
    end

    render json: @asset,
           serializer: AssetSerializer,
           user: current_user
  end

  def create
    @step = Step.new(
      name: t('protocols.steps.default_name'),
      completed: false,
      user: current_user,
      last_modified_by: current_user
    )

    @step = @protocol.insert_step(@step, params[:position])
    if @protocol.in_repository? && @protocol.errors.present?
      return render json: { error: @protocol.errors }, status: :unprocessable_entity
    end

    # Generate activity
    if @protocol.in_module?
      log_activity(:create_step, @my_module.experiment.project, { my_module: @my_module.id }.merge(step_message_items))
    else
      log_activity(:add_step_to_protocol_repository, nil, { protocol: @protocol.id }.merge(step_message_items))
    end
    render json: @step, serializer: StepSerializer, user: current_user
  end

  def show
    render json: {
      html: render_to_string(
        partial: 'steps/step',
        locals: { step: @step },
        formats: :html
      )
    }
  end

  def update
    if @step.update(step_params)
      # Generate activity
      if @protocol.in_module?
        log_activity(
          :edit_step, @my_module.experiment.project,
          { my_module: @my_module.id }.merge(step_message_items)
        )
      else
        log_activity(
          :edit_step_in_protocol_repository,
          nil,
          { protocol: @protocol.id }.merge(step_message_items)
        )
      end
      render json: @step, serializer: StepSerializer, user: current_user
    else
      render json: @protocol.errors.present? ? { errors: @protocol.errors } : {}, status: :unprocessable_entity
    end
  end

  def duplicate
    ActiveRecord::Base.transaction do
      position = @step.position
      @protocol.steps.where('position > ?', position).order(position: :desc).each do |step|
        step.update(position: step.position + 1)
      end
      new_step = @step.duplicate(@protocol, current_user, step_position: position + 1, step_name: @step.name + ' (1)')

      if @protocol.in_module?
        log_activity(
          :task_step_duplicated, @my_module.experiment.project,
          { my_module: @my_module.id }.merge(step_message_items)
        )
      else
        log_activity(
          :protocol_step_duplicated,
          nil,
          { protocol: @protocol.id }.merge(step_message_items)
        )
      end

      render json: new_step, serializer: StepSerializer, user: current_user
    end
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end

  def update_view_state
    view_state = @step.current_view_state(current_user)
    view_state.state['assets']['sort'] = params.require(:assets).require(:order)
    view_state.save! if view_state.changed?

    render json: {}, status: :ok
  end

  def update_asset_view_mode
    html = ''
    ActiveRecord::Base.transaction do
      @step.assets_view_mode = params[:assets_view_mode]
      @step.save!(touch: false)
      @step.assets.update_all(view_mode: @step.assets_view_mode)
    end
    render json: { view_mode: @step.assets_view_mode }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error(e.message)
    render json: { errors: e.message }, status: :unprocessable_entity
  end

  def destroy
    if @step.can_destroy?

      # Calculate space taken by this step
      team = @protocol.team
      previous_size = @step.space_taken

      # Generate activity
      if @protocol.in_module?
        log_activity(
          :destroy_step,
          @my_module.experiment.project,
          { my_module: @my_module.id }.merge(step_message_items)
        )
      else
        log_activity(:delete_step_in_protocol_repository, nil, { protocol: @protocol.id }.merge(step_message_items))
      end

      # Destroy the step
      @step.destroy

      # Release space taken by the step
      team.release_space(previous_size)
      team.save
    end

    render json: @step, serializer: StepSerializer, user: current_user
  end

  # Complete/uncomplete step
  def toggle_step_state
    @step.completed = params[:completed] == 'true'
    @step.last_modified_by = current_user

    if @step.save
      # Create activity
      if @step.saved_change_to_completed
        completed_steps = @protocol.steps.where(completed: true).count
        all_steps = @protocol.steps.count

        type_of = @step.completed ? :complete_step : :uncomplete_step
        # Toggling step state can only occur in
        # module protocols, so my_module is always
        # not nil; nonetheless, check if my_module is present
        if @protocol.in_module?
          log_activity(
            type_of,
            @protocol.my_module.experiment.project,
            {
              my_module: @my_module.id,
              num_completed: completed_steps.to_s,
              num_all: all_steps.to_s
            }.merge(step_message_items)
          )
        end
      end
      render json: @step, serializer: StepSerializer, user: current_user
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def reorder
    @protocol.with_lock do
      params[:step_positions].each do |id, position|
        @protocol.steps.find(id).update_column(:position, position)
      end

      if @protocol.in_module?
        log_activity(:task_steps_rearranged, @my_module.experiment.project, my_module: @my_module.id)
      else
        log_activity(:protocol_steps_rearranged, nil, protocol: @protocol.id)
      end
      @protocol.touch
    end

    render json: {
      steps_order: @protocol.steps.order(:position).select(:id, :position)
    }
  end

  private

  def load_vars
    @step = Step.find_by(id: params[:id])
    return render_404 unless @step

    @protocol = @step.protocol
    @chk_item = ChecklistItem.find_by(id: params[:checklistitem_id]) if params[:checklistitem_id]
    @my_module = @protocol.my_module if @protocol.in_module?
  end

  def load_vars_nested
    @protocol = Protocol.find_by(id: params[:protocol_id])

    return render_404 unless @protocol

    @my_module = @protocol.my_module if @protocol.in_module?
  end

  def convert_table_contents_to_utf8
    if params.include? :step and
      params[:step].include? :tables_attributes then
      params[:step][:tables_attributes].each do |k,v|
        params[:step][:tables_attributes][k][:contents] =
          v[:contents].encode(Encoding::UTF_8).force_encoding(Encoding::UTF_8)
      end
    end
  end

  def check_view_permissions
    render_403 unless can_read_protocol_in_module?(@protocol) || can_read_protocol_in_repository?(@protocol)
  end

  def check_protocol_manage_permissions
    render_403 unless can_manage_protocol_in_module?(@protocol) || can_manage_protocol_draft_in_repository?(@protocol)
  end

  def check_manage_permissions
    render_403 unless can_manage_step?(@step)
  end

  def check_create_permissions
    if @my_module
      render_403 unless can_manage_my_module_steps?(@my_module)
    else
      render_403 unless can_manage_protocol_draft_in_repository?(@protocol)
    end
  end

  def check_complete_and_checkbox_permissions
    render_403 unless can_complete_or_checkbox_step?(@protocol)
  end

  def step_params
    params.require(:step).permit(:name)
  end

  def log_activity(type_of, project = nil, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @protocol,
            team: @protocol.team,
            project: project,
            message_items: message_items)
  end

  def step_message_items
    {
      step: {
        id: @step.id,
        value_for: 'name'
      },
      step_position: {
        id: @step.id,
        value_for: 'position_plus_one'
      }
    }
  end
end
