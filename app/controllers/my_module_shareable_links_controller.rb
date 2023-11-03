# frozen_string_literal: true

class MyModuleShareableLinksController < ApplicationController
  before_action :load_my_module, except: %i(protocol_show
                                            repository_index_dt
                                            repository_snapshot_index_dt
                                            download_asset
                                            results_show)
  before_action :check_view_permissions, only: :show
  before_action :check_manage_permissions, except: %i(protocol_show
                                                      show
                                                      repository_index_dt
                                                      repository_snapshot_index_dt
                                                      download_asset
                                                      results_show)
  before_action :shareable_link_load_my_module, only: %i(protocol_show
                                                         repository_index_dt
                                                         repository_snapshot_index_dt
                                                         download_asset
                                                         results_show)
  before_action :load_repository, only: :repository_index_dt
  before_action :load_repository_snapshot, only: :repository_snapshot_index_dt
  skip_before_action :authenticate_user!, only: %i(protocol_show
                                                   repository_index_dt
                                                   repository_snapshot_index_dt
                                                   download_asset
                                                   results_show)
  skip_before_action :verify_authenticity_token, only: %i(protocol_show
                                                          repository_index_dt
                                                          repository_snapshot_index_dt)
  after_action -> { request.session_options[:skip] = true }

  def show
    render json: @my_module.shareable_link, serializer: ShareableLinksSerializer
  end

  def protocol_show
    render 'shareable_links/my_module_protocol_show', layout: 'shareable_links'
  end

  def results_show
    @results_order = params[:order] || 'new'

    @results = @my_module.results.active
    @results = @results.page(params[:page]).per(Constants::RESULTS_PER_PAGE_LIMIT)

    @results = case @results_order
               when 'old' then @results.order(created_at: :asc)
               when 'old_updated' then @results.order(updated_at: :asc)
               when 'new_updated' then @results.order(updated_at: :desc)
               when 'atoz' then @results.order(name: :asc)
               when 'ztoa' then @results.order(name: :desc)
               else @results.order(created_at: :desc)
               end

    @gallery = @results.left_joins(:assets).pluck('assets.id').compact

    render 'shareable_links/my_module_results_show', layout: 'shareable_links'
  end

  def repository_index_dt
    @draw = params[:draw].to_i
    per_page = params[:length].to_i < 1 ? Constants::REPOSITORY_DEFAULT_PAGE_SIZE : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositoryDatatableService.new(@repository, params, nil, @my_module)

    @datatable_params = {
      view_mode: params[:view_mode],
      my_module: @my_module,
      include_stock_consumption: @repository.has_stock_management? && params[:assigned].present?,
      disable_reminders: true, # reminders are always disabled for shareable links
      disable_stock_management: true # stock management is always disabled in MyModule context
    }

    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings

    @repository_rows = datatable_service.repository_rows.page(page).per(per_page)

    render 'repository_rows/simple_view_index'
  end

  def repository_snapshot_index_dt
    @draw = params[:draw].to_i
    per_page = params[:length].to_i < 1 ? Constants::REPOSITORY_DEFAULT_PAGE_SIZE : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositorySnapshotDatatableService.new(@repository_snapshot, params, nil, @my_module)

    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings

    @repository = @repository_snapshot
    @repository_rows = datatable_service.repository_rows.page(page).per(per_page)

    render 'repository_rows/simple_view_index'
  end

  def download_asset
    @asset = @my_module.assets_in_steps.find_by(id: params[:id]) ||
             @my_module.assets_in_results.find_by(id: params[:id])

    return render_404 if @asset.blank?

    redirect_to @asset.file.url(expires_in: Constants::URL_SHORT_EXPIRE_TIME.minutes, disposition: 'attachment'),
                allow_other_host: true
  end

  def create
    @my_module.create_shareable_link(
      uuid: @my_module.signed_id(expires_in: 999.years),
      description: params[:description],
      team: @my_module.team,
      created_by: current_user
    )

    log_activity(:task_link_sharing_enabled)

    render json: @my_module.shareable_link, serializer: ShareableLinksSerializer
  end

  def update
    @my_module.shareable_link.update!(
      description: params[:description],
      last_modified_by: current_user
    )

    log_activity(:shared_task_message_edited)

    render json: @my_module.shareable_link, serializer: ShareableLinksSerializer
  end

  def destroy
    @my_module.shareable_link.destroy!

    log_activity(:task_link_sharing_disabled)

    render json: {}
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])
    render_404 unless @my_module
  end

  def shareable_link_load_my_module
    @shareable_link = ShareableLink.find_by(uuid: params[:uuid])

    return render_404 if @shareable_link.blank?

    @my_module = @shareable_link.shareable
  end

  def load_repository
    @repository = @my_module.assigned_repositories.find_by(id: params[:id])
    render_404 unless @repository
  end

  def load_repository_snapshot
    @repository_snapshot = @my_module.repository_snapshots.find_by(id: params[:id])
    render_404 unless @repository_snapshot
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_share_my_module?(@my_module)
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: @my_module.team,
            project: @my_module.project,
            subject: @my_module,
            message_items: {
              my_module: @my_module.id,
              user: current_user.id
            })
  end
end
