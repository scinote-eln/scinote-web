# frozen_string_literal: true

class StepOrderableElementsController < ApplicationController
  before_action :load_vars_nested
  before_action :load_vars, only: :destroy
  before_action :check_view_permissions, except: %i(create destroy)
  before_action :check_manage_permissions, only: %i(create destroy)

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

  def update
    if @step_orderable_element.move_to(params[:new_position].to_i)
      render json: @step_orderable_element, serializer: StepOrderableElementSerializer
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def destroy
    if @step_orderable_element.destroy
      render json: @step_orderable_element, serializer: StepOrderableElementSerializer
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  private

  def load_vars
    @step_orderable_element = @step.step_orderable_elements.find_by(id: params[:id])
    render_404 unless @step_orderable_element
  end

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
