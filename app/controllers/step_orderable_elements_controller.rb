# frozen_string_literal: true

class StepOrderableElementsController < ApplicationController
  before_action :load_vars_nested
  before_action :check_manage_permissions

  def reorder
    @step.with_lock do
      params[:step_orderable_element_positions].each do |id, position|
        @step.step_orderable_elements.find(id).update_column(:position, position)
      end

      if @protocol.in_module?
        log_activity(:task_step_content_rearranged, @my_module.experiment.project, my_module: @my_module.id)
      else
        log_activity(:protocol_step_content_rearranged, nil, protocol: @protocol.id)
      end
      @step.touch
    end

    render json: params[:step_orderable_element_positions], status: :ok
  end

  private

  def load_vars_nested
    @step = Step.find_by(id: params[:step_id])
    return render_404 unless @step

    @protocol = @step.protocol
    @my_module = @protocol.my_module
  end

  def check_view_permissions
    render_403 unless can_read_protocol_in_module?(@protocol) || can_read_protocol_in_repository?(@protocol)
  end

  def check_manage_permissions
    render_403 unless can_manage_step?(@step)
  end

  def log_activity(type_of, project = nil, message_items = {})
    default_items = { step: @step.id,
                      step_position: { id: @step.id, value_for: 'position_plus_one' } }
    message_items = default_items.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @protocol,
            team: @protocol.team,
            project: project,
            message_items: message_items)
  end
end
