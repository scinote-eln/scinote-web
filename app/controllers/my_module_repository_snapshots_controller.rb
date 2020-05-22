# frozen_string_literal: true

class MyModuleRepositorySnapshotsController < ApplicationController
  before_action :load_my_module
  before_action :load_repository, only: :create
  before_action :load_repository_snapshot, except: %i(create full_view_sidebar select)
  before_action :check_view_permissions, except: %i(create destroy select)
  before_action :check_manage_permissions, only: %i(create destroy select)

  def index_dt
    @draw = params[:draw].to_i
    per_page = params[:length] == '-1' ? Constants::REPOSITORY_DEFAULT_PAGE_SIZE : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositorySnapshotDatatableService.new(@repository_snapshot, params, current_user, @my_module)

    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings
    if params[:simple_view]
      repository_rows = datatable_service.repository_rows
      rows_view = 'repository_rows/simple_view_index.json'
    else
      repository_rows = datatable_service.repository_rows
                                         .preload(:repository_columns,
                                                  :created_by,
                                                  repository_cells: @repository_snapshot.cell_preload_includes)
      rows_view = 'repository_rows/snapshot_index.json'
    end
    @repository_rows = repository_rows.page(page).per(per_page)

    render rows_view
  end

  def create
    repository_snapshot = @repository.provision_snapshot(@my_module, current_user)

    render json: {
      html: render_to_string(partial: 'my_modules/repositories/full_view_version',
                             locals: { repository_snapshot: repository_snapshot,
                                       can_delete_snapshot: can_manage_module?(@my_module) })
    }
  end

  def status
    render json: {
      status: @repository_snapshot.status
    }
  end

  def show
    render json: {
      html: render_to_string(partial: 'my_modules/repositories/full_view_version',
                             locals: { repository_snapshot: @repository_snapshot,
                                       can_delete_snapshot: can_manage_module?(@my_module) })
    }
  end

  def destroy
    @repository_snapshot.destroy!
    render json: {}
  end

  def full_view_table
    render json: {
      html: render_to_string(partial: 'my_modules/repositories/full_view_snapshot_table')
    }
  end

  def full_view_sidebar
    @repository = Repository.find_by(id: params[:repository_id])

    if @repository.present?
      return render_403 unless can_read_repository?(@repository)
    end

    @repository_snapshots = @my_module.repository_snapshots.where(parent_id: params[:repository_id])
    render json: { html: render_to_string(partial: 'my_modules/repositories/full_view_sidebar') }
  end

  def select
    if params[:repository_id]
      @my_module.repository_snapshots.where(parent_id: params[:repository_id]).update(selected: nil)
    else
      repository_snapshot = @my_module.repository_snapshots.find_by(id: params[:repository_snapshot_id])
      return render_404 unless repository_snapshot

      @my_module.repository_snapshots
                .where(original_repository: repository_snapshot.original_repository)
                .update(selected: nil)
      repository_snapshot.update!(selected: true)
    end

    render json: {}
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
    render_403 unless can_manage_module?(@my_module)
  end
end
