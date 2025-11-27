# frozen_string_literal: true

class StepResultsController < StepResultsBaseController

  private

  def load_results
    @results = Result.where(id: params[:result_ids])

    render_404 and return if (action_name == 'link_steps') && @results.size != 1

    render_403 and return if @results.pluck(:my_module_id).uniq.size > 1
  end

  def check_manage_permissions
    case action_name
    when 'link_results'
      render_403 and return unless can_manage_my_module?(@steps.first.my_module)
    when 'link_steps'
      render_403 and return unless can_manage_my_module?(@results.first.my_module)
    end

    render_403 and return unless (@results + @steps).map(&:my_module).uniq.one?
  end
end
