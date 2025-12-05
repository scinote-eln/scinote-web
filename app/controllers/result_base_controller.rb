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

        @results = @results.includes(:assets, result_orderable_elements: :orderable).page(params.dig(:page, :number) || 1)
        render json: @results,
               each_serializer: result_serializer,
               include: %i(result_orderable_elements assets),
               user: current_user,
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
    @result = @parent.results.create!(user: current_user, last_modified_by: current_user)
    log_activity(:"add_#{model_parameter}", { "#{model_parameter}": @result })

    render json: @result,
           serializer: result_serializer,
           include: %i(result_orderable_elements assets),
           user: current_user
  end

  def update
    @result.update!(result_params.merge(last_modified_by: current_user))
    log_activity(:"edit_#{model_parameter}", { "#{model_parameter}": @result })
    render json: @result,
           serializer: result_serializer,
           include: %i(result_orderable_elements assets),
           user: current_user
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

      log_activity(:"#{model_parameter}_file_added", { file: @asset.file_name, "#{model_parameter}": @result })
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
      message_items = { "destroyed_#{model_parameter}": name }
      message_items[:protocol] = @parent.id if model_parameter == 'result_template'
      log_activity(:"destroy_#{model_parameter}", message_items)
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

      log_activity(:"#{model_parameter}_duplicated", { "#{model_parameter}": @result })
      render json: new_result,
             serializer: result_serializer,
             include: %i(result_orderable_elements assets),
             user: current_user
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

  def model_parameter
    @result.class.model_name.param_key
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
      @results = @results.search(current_user, params[:view_mode] == 'archived', params[:query])
                         .page(params[:page] || 1)
                         .per(Constants::SEARCH_LIMIT)
    end

    @results = @results.where('results.created_at >= ?', params[:created_at_from]) if params[:created_at_from]
    @results = @results.where('results.created_at <= ?', params[:created_at_to]) if params[:created_at_to]
    @results = @results.where('results.updated_at >= ?', params[:updated_at_from]) if params[:updated_at_from]
    @results = @results.where('results.updated_at <= ?', params[:updated_at_to]) if params[:updated_at_to]
  end

  def log_activity(element_type_of, message_items = {})
    subject = if (result = message_items[:result])
                message_items[:result] = result.id
                result
              elsif (template = message_items[:result_template])
                message_items[:result_template] = template.id
                message_items[:protocol] = @parent.id
                template
              else
                @parent
              end

    Activities::CreateActivityService.call(
      activity_type: element_type_of,
      owner: current_user,
      team: @parent.team,
      subject: subject,
      project: @parent.is_a?(Protocol) ? nil : @parent&.experiment&.project,
      message_items: message_items
    )
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
