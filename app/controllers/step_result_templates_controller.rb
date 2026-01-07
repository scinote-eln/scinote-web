# frozen_string_literal: true

class StepResultTemplatesController < StepResultsBaseController

  private

  def load_results
    @results = ResultTemplate.where(id: params[:result_ids])

    render_404 and return if (action_name == 'link_steps') && @results.size != 1

    render_403 and return if @results.pluck(:protocol_id).uniq.size > 1
  end

  def check_manage_permissions
    case action_name
    when 'link_results'
      render_403 and return unless can_manage_protocol_draft_in_repository?(@steps.first.protocol)
    when 'link_steps'
      render_403 and return unless can_manage_protocol_draft_in_repository?(@results.first.protocol)
    end

    render_403 and return unless (@results + @steps).map(&:protocol).uniq.one?
  end
end
