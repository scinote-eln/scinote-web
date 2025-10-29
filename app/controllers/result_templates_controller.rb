# frozen_string_literal: true

class ResultTemplatesController < ResultBaseController

  before_action :load_parent
  before_action :load_vars, only: %i(destroy elements assets upload_attachment destroy
                                     update_view_state update_asset_view_mode update duplicate)
  before_action :set_inline_name_editing, only: :index
  before_action :set_breadcrumbs_items, only: %i(index)
  before_action :check_destroy_permissions, only: :destroy

  def list
    if params[:with_linked_step_id].present?
      step = @parent.steps.find_by(id: params[:with_linked_step_id])
      @results = @parent.results.or(@parent.results.where(id: step.results.select(:id)))
    else
      @results = @parent.results
    end

    update_and_apply_user_sort_preference!
  end

  def assets
    render json: @result.assets.preload(:preview_image_attachment, file_attachment: :blob, result: { protocol: { user_assignments: %i(user user_role) } }),
           each_serializer: AssetSerializer,
           user: current_user,
           managable_result: can_manage_result?(@result)
  end

  private

  def load_parent
    @parent = Protocol.readable_by_user(current_user).find(params[:protocol_id])
    current_team_switch(@parent.team) if current_team != @parent.team

    @protocol = @parent # For header partial
  end

  def load_vars
    @result = @parent.results.find(params[:id])

    return render_403 unless @result
  end

  def set_breadcrumbs_items
    archived = params[:view_mode] || (@parent&.archived? && 'archived')

    @breadcrumbs_items = []
    @breadcrumbs_items.push(
      { label: t('breadcrumbs.protocols'), url: protocols_path(view_mode: archived ? 'archived' : nil) }
    )

    if @parent
      @breadcrumbs_items.push(
        { label: @parent.name, url: protocol_path(@parent) }
      )
    end

    @breadcrumbs_items.each do |item|
      item[:label] = "#{t('labels.archived')} #{item[:label]}" if archived
    end
  end

  def set_inline_name_editing
    return unless can_manage_protocol_draft_in_repository?(@parent)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'protocol',
      item_id: @parent.id,
      field_to_udpate: 'name',
      path_to_update: name_protocol_path(@parent)
    }
  end

  def result_serializer
    ResultTemplateSerializer
  end

  def result_sorting_preference_key
    'result_templates_order'
  end

  def result_state_preference_key
    'result_template_states'
  end
end
