# frozen_string_literal: true

class MyModuleRepositorySnapshotsController < ApplicationController
  before_action :load_my_module
  before_action :load_repository
  before_action :load_repository_snapshot, except: %i(create full_view_versions_sidebar)
  before_action :check_view_permissions, except: %i(create destroy)
  before_action :check_manage_permissions, only: %i(create destroy)

  def index_dt
    @draw = params[:draw].to_i
    per_page = params[:length] == '-1' ? Constants::REPOSITORY_DEFAULT_PAGE_SIZE : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositorySnapshotDatatableService.new(@repository_snapshot, params, current_user, @my_module)

    @datatable_params = {
      view_mode: params[:view_mode],
      skip_custom_columns: params[:skip_custom_columns]
    }
    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings
    @repository_rows = datatable_service.repository_rows
                                        .preload(:repository_columns,
                                                 :created_by,
                                                 repository_cells: @repository_snapshot.cell_preload_includes)
                                        .page(page)
                                        .per(per_page)

    render 'repository_rows/snapshot_index.json'
  end

  def create
    service = Repositories::MyModuleAssigningSnapshotService.call(repository: @repository,
                                                                  my_module: @my_module,
                                                                  user: current_user)

    if service.succeed?
      @repository_snapshots = @my_module.repository_snapshots.where(original_repository: @repository)
      render json: { html: render_to_string(partial: 'my_modules/repositories/full_view_versions_sidebar') }
    else
      render json: service.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @repository_snapshot.destroy!
    @repository_snapshots = @my_module.repository_snapshots.where(original_repository: @repository)
    render json: { html: render_to_string(partial: 'my_modules/repositories/full_view_versions_sidebar') }
  end

  def full_view_table
    render json: {
      html: render_to_string(partial: 'my_modules/repositories/full_view_snapshot_table')
    }
  end

  def full_view_versions_sidebar
    @repository_snapshots = @my_module.repository_snapshots.where(original_repository: @repository)
    render json: { html: render_to_string(partial: 'my_modules/repositories/full_view_versions_sidebar') }
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])
    render_404 unless @my_module
  end

  def load_repository
    @repository = Repository.find_by(id: params[:repository_id])
    render_404 unless @repository
    render_403 unless can_read_repository?(@repository)
  end

  def load_repository_snapshot
    @repository_snapshot = @my_module.repository_snapshots.find_by(id: params[:id])
    render_404 unless @repository_snapshot
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@my_module.experiment)
  end

  def check_manage_permissions
    render_403 unless can_read_experiment?(@my_module.experiment)
  end
end
