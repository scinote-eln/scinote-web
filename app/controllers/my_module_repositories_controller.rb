# frozen_string_literal: true

class MyModuleRepositoriesController < ApplicationController
  include ApplicationHelper

  before_action :load_my_module
  before_action :load_repository, except: %i(repositories_dropdown_list repositories_list_html)
  before_action :check_my_module_view_permissions, except: %i(update consume_modal update_consumption)
  before_action :check_repository_view_permissions, except: %i(repositories_dropdown_list repositories_list_html)
  before_action :check_repository_row_consumption_permissions, only: %i(consume_modal update_consumption)
  before_action :check_assign_repository_records_permissions, only: :update

  def index_dt
    @draw = params[:draw].to_i
    per_page = params[:length].to_i < 1 ? Constants::REPOSITORY_DEFAULT_PAGE_SIZE : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositoryDatatableService.new(@repository, params, current_user, @my_module)

    @datatable_params = {
      view_mode: params[:view_mode],
      my_module: @my_module
    }
    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings
    if params[:simple_view]
      repository_rows = datatable_service.repository_rows
      rows_view = 'repository_rows/simple_view_index.json'
    else
      repository_rows = datatable_service.repository_rows
                                         .preload(:repository_columns,
                                                  :created_by,
                                                  repository_cells: { value: @repository.cell_preload_includes })
      rows_view = 'repository_rows/index.json'
    end
    @repository_rows = repository_rows.page(page).per(per_page)

    render rows_view
  end

  def update
    service = RepositoryRows::MyModuleAssignUnassignService.call(my_module: @my_module,
                                                                 repository: @repository,
                                                                 user: current_user,
                                                                 params: params)
    if service.succeed? &&
       (service.assigned_rows_count.positive? ||
         service.unassigned_rows_count.positive?)
      flash = update_flash_message(service)
      status = :ok
    else
      flash = t('my_modules.repository.flash.update_error')
      status = :bad_request
    end

    respond_to do |format|
      format.json do
        render json: {
          flash: flash,
          rows_count: @my_module.repository_rows_count(@repository),
          repository_id: @repository.repository_snapshots.find_by(selected: true)&.id || @repository.id
        }, status: status
      end
    end
  end

  def update_repository_records_modal
    modal = render_to_string(
      partial: 'my_modules/modals/update_repository_records_modal_content.html.erb',
      locals: { my_module: @my_module,
                repository: @repository,
                selected_rows: params[:selected_rows],
                downstream: params[:downstream] }
    )
    render json: {
      html: modal,
      update_url: my_module_repository_path(@my_module, @repository)
    }, status: :ok
  end

  def assign_repository_records_modal
    modal = render_to_string(
      partial: 'my_modules/modals/assign_repository_records_modal_content.html.erb',
      locals: { my_module: @my_module,
                repository: @repository,
                selected_rows: params[:selected_rows],
                downstream: params[:downstream] }
    )
    render json: {
      html: modal,
      update_url: my_module_repository_path(@my_module, @repository)
    }, status: :ok
  end

  def repositories_list_html
    @assigned_repositories = @my_module.live_and_snapshot_repositories_list
    render json: {
      html: render_to_string(partial: 'my_modules/repositories/repositories_list'),
      assigned_rows_count: @assigned_repositories.map(&:assigned_rows_count).sum
    }
  end

  def full_view_table
    render json: {
      html: render_to_string(partial: 'my_modules/repositories/full_view_table')
    }
  end

  def repositories_dropdown_list
    @repositories = Repository.accessible_by_teams(current_team).joins("
                                LEFT OUTER JOIN repository_rows ON
                                  repository_rows.repository_id = repositories.id
                                LEFT OUTER JOIN my_module_repository_rows ON
                                  my_module_repository_rows.repository_row_id = repository_rows.id
                                  AND my_module_repository_rows.my_module_id = #{@my_module.id}
                              ").select('COUNT(DISTINCT my_module_repository_rows.id) as rows_count, repositories.*')
                              .group(:id)
                              .having('COUNT(my_module_repository_rows.id) > 0 OR repositories.archived = FALSE')
                              .order(:name)

    render json: { html: render_to_string(partial: 'my_modules/repositories/repositories_dropdown_list') }
  end

  def export_repository
    if params[:header_ids]
      RepositoryZipExport.generate_zip(params, @repository, current_user)

      Activities::CreateActivityService.call(
        activity_type: :export_inventory_items_assigned_to_task,
        owner: current_user,
        subject: @my_module,
        team: current_team,
        message_items: {
          my_module: @my_module.id,
          repository: @repository.id
        }
      )

      render json: { message: t('zip_export.export_request_success') }, status: :ok
    else
      render json: { message: t('zip_export.export_error') }, status: :unprocessable_entity
    end
  end

  def consume_modal
    @repository_row = @repository.repository_rows.find(params[:row_id])
    @module_repository_row = @my_module.my_module_repository_rows.find_by(repository_row: @repository_row)
    @stock_value = @module_repository_row.repository_row.repository_stock_value
    render json: {
      html: render_to_string(
        partial: 'my_modules/repositories/consume_stock_modal_content.html.erb'
      )
    }
  end

  def update_consumption
    module_repository_row = @my_module.my_module_repository_rows.find_by(id: params[:module_row_id])
    module_repository_row.with_lock do
      module_repository_row.assign_attributes(
        stock_consumption: params[:stock_consumption],
        last_modified_by: current_user,
        comment: params[:comment]
      )
      module_repository_row.save!
    end

    render json: {}, status: :ok
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])
    render_404 unless @my_module
  end

  def load_repository
    @repository = Repository.find_by(id: params[:id])
    render_404 unless @repository
  end

  def check_my_module_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_repository_view_permissions
    render_403 unless can_read_repository?(@repository)
  end

  def check_assign_repository_records_permissions
    render_403 unless can_assign_my_module_repository_rows?(@my_module)
  end

  def check_repository_row_consumption_permissions
    render_403 unless can_update_my_module_stock_consumption?(@my_module)
  end

  def update_flash_message(service)
    assigned_count = service.assigned_rows_count
    unassigned_count = service.unassigned_rows_count

    if params[:downstream] == 'true'
      if assigned_count && unassigned_count
        t('my_modules.repository.flash.assign_and_unassign_from_task_and_downstream_html',
          assigned_items: assigned_count,
          unassigned_items: unassigned_count)
      elsif assigned_count
        t('my_modules.repository.flash.assign_to_task_and_downstream_html',
          assigned_items: assigned_count)
      elsif unassigned_count
        t('my_modules.repository.flash.unassign_from_task_and_downstream_html',
          unassigned_items: unassigned_count)
      end
    elsif assigned_count && unassigned_count
      t('my_modules.repository.flash.assign_and_unassign_from_task_html',
        assigned_items: assigned_count,
        unassigned_items: unassigned_count)
    elsif assigned_count
      t('my_modules.repository.flash.assign_to_task_html',
        assigned_items: assigned_count)
    elsif unassigned_count
      t('my_modules.repository.flash.unassign_from_task_html',
        unassigned_items: unassigned_count)
    end
  end
end
