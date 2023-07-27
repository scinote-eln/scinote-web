# frozen_string_literal: true

class ResultOrderableElementsController < ApplicationController
  before_action :load_vars_nested
  before_action :check_manage_permissions

  def reorder
    @result.with_lock do
      params[:result_orderable_element_positions].each do |id, position|
        @result.result_orderable_elements.find(id).update_column(:position, position)
      end

      log_activity(:result_content_rearranged, @my_module.experiment.project, my_module: @my_module.id)

      @result.touch
    end

    render json: params[:result_orderable_element_positions], status: :ok
  end

  private

  def load_vars_nested
    @result = Result.find_by(id: params[:result_id])
    return render_404 unless @result

    @my_module = @result.my_module
  end

  def check_manage_permissions
    render_403 unless can_manage_result?(@result)
  end

  def log_activity(type_of, project = nil, message_items = {})
    default_items = { result: @result.id }
    message_items = default_items.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @result,
            team: @@my_module.team,
            project: project,
            message_items: message_items)
  end
end
