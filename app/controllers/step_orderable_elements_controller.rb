# frozen_string_literal: true

class StepOrderableElementsController < ApplicationController
  before_action :load_vars_nested
  before_action :check_manage_permissions

  def reorder
    ActiveRecord::Base.transaction do
      params[:step_orderable_element_positions].each do |id, position|
        @step.step_orderable_elements.find(id).update_column(:position, position)
      end
    end

    render json: params[:step_orderable_element_positions], status: :ok
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
