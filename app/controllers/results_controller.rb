# frozen_string_literal: true

class ResultsController < ResultBaseController

  before_action :load_parent
  before_action :load_vars, only: %i(destroy elements assets upload_attachment archive restore destroy
                                     update_view_state update_asset_view_mode update duplicate)
  before_action :set_breadcrumbs_items, only: %i(index)
  before_action :set_navigator, only: %i(index)
  before_action :set_inline_name_editing, only: %i(index)
  before_action :check_destroy_permissions, only: :destroy

  def list
    if params[:with_linked_step_id].present?
      step = @parent.protocol.steps.find_by(id: params[:with_linked_step_id])
      @results = @parent.results.where(archived: false).or(@parent.results.where(id: step.results.select(:id)))
    else
      @results = @parent.results.active
    end

    update_and_apply_user_sort_preference!
  end

  def archive
    if @result.archive(current_user)
      log_activity(:archive_result, { result: @result })
      render json: {}, status: :ok
    else
      render json: { errors: @result.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def assets
    render json: @result.assets.preload(:preview_image_attachment, file_attachment: :blob, result: { my_module: { experiment: :project, user_assignments: %i(user user_role) } }),
           each_serializer: AssetSerializer,
           user: current_user,
           managable_result: can_manage_result?(@result)
  end

  def restore
    if @result.restore(current_user)
      log_activity(:result_restored, { result: @result })
      render json: {}, status: :ok
    else
      render json: { errors: @result.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def load_parent
    @parent = MyModule.readable_by_user(current_user).find(params[:my_module_id])
    current_team_switch(@parent.team) if current_team != @parent.team

    @my_module = @parent # For header partial
  end

  def load_vars
    @result = @parent.results.find(params[:id])

    return render_403 unless @result
  end

  def set_navigator
    @navigator = {
      url: tree_navigator_my_module_path(@parent),
      archived: @parent.archived_branch?,
      id: @parent.code
    }
  end

  def log_activity(element_type_of, message_items = {})
    message_items[:my_module] = @parent.id
    subject = if message_items.key?(:result)
                result = message_items[:result]
                message_items[:result] = result.id
                result
              else
                @parent
              end

    Activities::CreateActivityService.call(
      activity_type: element_type_of,
      owner: current_user,
      team: @parent.team,
      subject: subject,
      project: @parent.experiment.project,
      message_items: message_items
    )
  end

  def set_inline_name_editing
    return unless can_manage_my_module?(@parent)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'my_module',
      item_id: @parent.id,
      field_to_udpate: 'name',
      path_to_update: my_module_path(@parent)
    }
  end

  def result_serializer
    ResultSerializer
  end

  def result_sorting_preference_key
    'results_order'
  end

  def result_state_preference_key
    'result_states'
  end
end
