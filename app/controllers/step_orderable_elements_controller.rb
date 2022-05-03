# frozen_string_literal: true

class StepOrderableElementsController < ApplicationController
  before_action :load_vars_nested
  before_action :check_manage_permissions, only: :create

  def create
    ActiveRecord::Base.transaction do
      element = @step.step_orderable_elements.create!(
        position: @step.step_orderable_elements.length,
        orderable: create_step_element
      )
      render json: element, serializer: StepOrderableElementSerializer
    rescue ActiveRecord::RecordInvalid
      render json: {}, status: :unprocessable_entity
    end
  end

  private

  def load_vars_nested
    @step = Step.find_by(id: params[:step_id])
    return render_404 unless @step

    @protocol = @step.protocol
  end

  def check_view_permissions
    render_403 unless can_read_protocol_in_module?(@protocol) || can_read_protocol_in_repository?(@protocol)
  end

  def check_manage_permissions
    render_403 unless can_manage_step?(@step)
  end
end
