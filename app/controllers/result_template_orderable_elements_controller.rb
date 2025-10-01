# frozen_string_literal: true

class ResultTemplateOrderableElementsController < ApplicationController
  before_action :load_vars_nested
  before_action :check_manage_permissions

  def reorder
    position_changed = false
    ActiveRecord::Base.transaction do
      params[:result_orderable_element_positions].each do |id, position|
        result_element = @result.result_orderable_elements.find(id)
        if result_element.position != position
          position_changed = true
          result_element.update_column(:position, position)
        end
      end
    end

    @result.touch if position_changed

    render json: params[:result_orderable_element_positions], status: :ok
  rescue ActiveRecord::RecordInvalid
    render json: { errors: result_element.errors }, status: :conflict
  end

  private

  def load_vars_nested
    @result = ResultTemplate.find_by(id: params[:result_template_id])
    return render_404 unless @result

    @protocol = @result.protocol
  end

  def check_manage_permissions
    render_403 unless can_manage_result_template?(@result)
  end
end
