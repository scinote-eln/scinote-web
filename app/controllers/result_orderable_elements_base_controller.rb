# frozen_string_literal: true

class ResultOrderableElementsBaseController < ApplicationController
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

    if position_changed
      log_activity(:result_content_rearranged, @parent)
      @result.touch
    end

    render json: params[:result_orderable_element_positions], status: :ok
  rescue ActiveRecord::RecordInvalid
    render json: { errors: result_element.errors }, status: :conflict
  end

  private

  def load_vars_nested
    @result = ResultBase.find_by(id: params[:result_id] || params[:result_template_id])
    return render_404 unless @result

    @parent = @result.parent
  end

  def check_manage_permissions
    render_403 unless can_manage_result?(@result)
  end
end
