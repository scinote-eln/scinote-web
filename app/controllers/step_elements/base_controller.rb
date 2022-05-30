# frozen_string_literal: true

module StepElements
  class BaseController < ApplicationController
    before_action :load_step_and_protocol
    before_action :check_manage_permissions

    private

    def load_step_and_protocol
      @step = Step.find_by(id: params[:step_id])
      return render_404 unless @step

      @protocol = @step.protocol
    end

    def check_manage_permissions
      render_403 unless can_manage_step?(@step)
    end

    def create_in_step!(step, new_orderable)
      ActiveRecord::Base.transaction do
        new_orderable.save!

        step.step_orderable_elements.create!(
          position: step.step_orderable_elements.length,
          orderable: new_orderable
        )
      end
    end

    def render_step_orderable_element(orderable)
      step_orderable_element = orderable.step_orderable_elements.find_by!(step: @step)
      render json: step_orderable_element, serializer: StepOrderableElementSerializer, user: current_user
    end
  end
end
