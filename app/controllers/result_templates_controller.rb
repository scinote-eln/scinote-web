# frozen_string_literal: true

class ResultTemplatesController < ApplicationController
  include Breadcrumbs
  include TeamsHelper

  before_action :load_protocol
  before_action :load_vars, only: %i(destroy elements assets upload_attachment destroy
                                     update_view_state update_asset_view_mode update duplicate)
  before_action :check_destroy_permissions, only: :destroy
  before_action :set_inline_name_editing, only: :index
  before_action :set_breadcrumbs_items, only: %i(index)

  def index
    respond_to do |format|
      format.json do
        # API endpoint
        @results = @protocol.results

        update_and_apply_user_sort_preference!
        apply_filters!

        @results = @results.page(params.dig(:page, :number) || 1)

        render json: @results, each_serializer: ResultTemplateSerializer, scope: current_user,
               meta: { sort: @sort_preference }
      end

      format.html do
        # Main view
        @active_tab = :results
        render(:index, formats: :html)
      end
    end
  end

  def list
    @results = @protocol.results

    update_and_apply_user_sort_preference!
  end

  def create
    result = @protocol.results.create!(user: current_user, last_modified_by: current_user)
    render json: result
  end

  def update
    @result.update!(result_params.merge(last_modified_by: current_user))
    render json: @result
  end

  def elements
    render json: @result.result_orderable_elements.order(:position),
           each_serializer: ResultOrderableElementSerializer,
           user: current_user
  end

  def assets
    render json: @result.assets.preload(:preview_image_attachment, file_attachment: :blob, result: { my_module: { experiment: :project, user_assignments: %i(user user_role) } }),
           each_serializer: AssetSerializer,
           user: current_user,
           managable_result: can_manage_result_template?(@result)
  end

  def upload_attachment
    @result.transaction do
      @asset = @result.assets.create!(
        created_by: current_user,
        last_modified_by: current_user,
        team: @protocol.team,
        view_mode: @result.assets_view_mode
      )
      @asset.attach_file_version(params[:signed_blob_id])
      @asset.post_process_file
    end

    render json: @asset,
           serializer: AssetSerializer,
           user: current_user
  end

  def update_view_state
    view_state = @result.current_view_state(current_user)
    view_state.state['assets']['sort'] = params.require(:assets).require(:order)
    view_state.save! if view_state.changed?

    render json: {}, status: :ok
  end

  def update_asset_view_mode
    ActiveRecord::Base.transaction do
      @result.assets_view_mode = params[:assets_view_mode]
      @result.save!(touch: false)
      @result.assets.update_all(view_mode: @result.assets_view_mode)
    end
    render json: { view_mode: @result.assets_view_mode }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error(e.message)
    render json: { errors: e.message }, status: :unprocessable_entity
  end

  def destroy
    name = @result.name
    if @result.discard
      render json: {}, status: :ok
    else
      render json: { errors: @result.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def duplicate
    ActiveRecord::Base.transaction do
      new_result = @result.duplicate(
        @protocol, current_user, result_name: "#{@result.name} (1)"
      )

      render json: new_result, serializer: ResultTemplateSerializer, user: current_user
    end
  end

  def change_results_state
    @protocol.results.find_each do |result|
      current_user.settings['result_template_states'][result.id.to_s] = params[:collapsed].present?
    end
    current_user.save!
    render json: { status: :ok }
  end

  private

  def result_params
    params.require(:result).permit(:name)
  end

  def update_and_apply_user_sort_preference!
    if params[:sort].present?
      current_user.update_nested_setting(key: 'result_templates_order', id: @protocol.id.to_s, value: params[:sort])
      @sort_preference = params[:sort]
    else
      @sort_preference = current_user.settings.fetch('result_templates_order', {})[@protocol.id.to_s] || 'created_at_desc'
    end
    apply_sort!(@sort_preference)
  end

  def apply_sort!(sort_order)
    case sort_order
    when 'updated_at_asc'
      @results = @results.order('result_templates.updated_at' => :asc)
    when 'updated_at_desc'
      @results = @results.order('result_templates.updated_at' => :desc)
    when 'created_at_asc'
      @results = @results.order('result_templates.created_at' => :asc)
    when 'created_at_desc'
      @results = @results.order('result_templates.created_at' => :desc)
    when 'name_asc'
      @results = @results.order('result_templates.name' => :asc)
    when 'name_desc'
      @results = @results.order('result_templates.name' => :desc)
    end
  end

  def apply_filters!
    if params[:query].present?
      @results = @results.search(current_user, params[:query])
                         .page(params[:page] || 1)
                         .per(Constants::SEARCH_LIMIT)
    end

    @results = @results.where('result_templates.created_at >= ?', params[:created_at_from]) if params[:created_at_from]
    @results = @results.where('result_templates.created_at <= ?', params[:created_at_to]) if params[:created_at_to]
    @results = @results.where('result_templates.updated_at >= ?', params[:updated_at_from]) if params[:updated_at_from]
    @results = @results.where('result_templates.updated_at <= ?', params[:updated_at_to]) if params[:updated_at_to]
  end

  def load_protocol
    @protocol = Protocol.readable_by_user(current_user).find(params[:protocol_id])
    current_team_switch(@protocol.team) if current_team != @protocol.team
  end

  def load_vars
    @result = @protocol.results.find(params[:id])

    return render_403 unless @result

    @protocol = @result.protocol
  end

  def check_destroy_permissions
    render_403 unless can_delete_result_template?(@result)
  end

  def set_breadcrumbs_items
    archived = params[:view_mode] || (@protocol&.archived? && 'archived')

    @breadcrumbs_items = []
    @breadcrumbs_items.push(
      { label: t('breadcrumbs.protocols'), url: protocols_path(view_mode: archived ? 'archived' : nil) }
    )

    if @protocol
      @breadcrumbs_items.push(
        { label: @protocol.name, url: protocol_path(@protocol) }
      )
    end

    @breadcrumbs_items.each do |item|
      item[:label] = "#{t('labels.archived')} #{item[:label]}" if archived
    end
  end

  def set_inline_name_editing
    return unless can_manage_protocol_draft_in_repository?(@protocol)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'protocol',
      item_id: @protocol.id,
      field_to_udpate: 'name',
      path_to_update: name_protocol_path(@protocol)
    }
  end
end
