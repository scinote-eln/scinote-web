# frozen_string_literal: true

class ResultBaseController < ApplicationController
  include Breadcrumbs
  include TeamsHelper

  def index
    respond_to do |format|
      format.json do
        # API endpoint
        @results = if params[:view_mode] == 'archived'
                     @parent.results.archived
                   else
                     @parent.results.active
                   end

        update_and_apply_user_sort_preference!
        apply_filters!

        @results = @results.page(params.dig(:page, :number) || 1)
        render json: @results, each_serializer: result_serializer, scope: current_user,
               meta: { sort: @sort_preference }
      end

      format.html do
        # Main view
        @active_tab = :results
        render(:index, formats: :html)
      end
    end
  end

  def create
    result = @parent.results.create!(user: current_user, last_modified_by: current_user)
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

  def upload_attachment
    @result.transaction do
      @asset = @result.assets.create!(
        created_by: current_user,
        last_modified_by: current_user,
        team: @parent.team,
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
      log_activity(:destroy_result, { destroyed_result: name })
      render json: {}, status: :ok
    else
      render json: { errors: @result.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def duplicate
    ActiveRecord::Base.transaction do
      new_result = @result.duplicate(
        @parent, current_user, result_name: "#{@result.name} (1)"
      )

      render json: new_result, serializer: result_serializer, user: current_user
    end
  end

  def change_results_state
    @parent.results.find_each do |result|
      current_user.settings[result_state_preference_key][result.id.to_s] = params[:collapsed].present?
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
      current_user.update_nested_setting(key: result_sorting_preference_key, id: @parent.id.to_s, value: params[:sort])
      @sort_preference = params[:sort]
    else
      @sort_preference = current_user.settings.fetch(result_sorting_preference_key, {})[@parent.id.to_s] || 'created_at_desc'
    end
    apply_sort!(@sort_preference)
  end

  def apply_sort!(sort_order)
    case sort_order
    when 'updated_at_asc'
      @results = @results.order('results.updated_at' => :asc)
    when 'updated_at_desc'
      @results = @results.order('results.updated_at' => :desc)
    when 'created_at_asc'
      @results = @results.order('results.created_at' => :asc)
    when 'created_at_desc'
      @results = @results.order('results.created_at' => :desc)
    when 'name_asc'
      @results = @results.order('results.name' => :asc)
    when 'name_desc'
      @results = @results.order('results.name' => :desc)
    end
  end

  def apply_filters!
    if params[:query].present?
      @results = @results.search(current_user, params[:query])
                         .page(params[:page] || 1)
                         .per(Constants::SEARCH_LIMIT)
    end

    @results = @results.where('results.created_at >= ?', params[:created_at_from]) if params[:created_at_from]
    @results = @results.where('results.created_at <= ?', params[:created_at_to]) if params[:created_at_to]
    @results = @results.where('results.updated_at >= ?', params[:updated_at_from]) if params[:updated_at_from]
    @results = @results.where('results.updated_at <= ?', params[:updated_at_to]) if params[:updated_at_to]
  end

  def check_destroy_permissions
    render_403 unless can_delete_result?(@result)
  end

  def result_serializer
    # To be defined in subclasses
  end

  def result_sorting_preference_key
    # To be defined in subclasses
  end

  def result_state_preference_key
    # To be defined in subclasses
  end
end
