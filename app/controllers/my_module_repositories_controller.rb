# frozen_string_literal: true

class MyModuleRepositoriesController < ApplicationController
  include ApplicationHelper

  before_action :load_my_module
  before_action :load_repository, except: %i(repositories_dropdown_list repositories_list_html create)
  before_action :check_my_module_view_permissions, except: %i(update consume_modal update_consumption)
  before_action :check_repository_view_permissions, except: %i(repositories_dropdown_list repositories_list_html create)
  before_action :check_repository_row_consumption_permissions, only: %i(consume_modal update_consumption)
  before_action :check_assign_repository_records_permissions, only: %i(update create)

  def index_dt
    @draw = params[:draw].to_i
    per_page = params[:length].to_i < 1 ? Constants::REPOSITORY_DEFAULT_PAGE_SIZE : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositoryDatatableService.new(@repository, params, current_user, @my_module)

    @datatable_params = {
      view_mode: params[:view_mode],
      my_module: @my_module,
      include_stock_consumption: @repository.has_stock_management? && params[:assigned].present?,
      disable_stock_management: true # stock management is always disabled in MyModule context
    }

    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings

    if params[:simple_view]
      repository_rows = datatable_service.repository_rows
      rows_view = 'repository_rows/simple_view_index'
    else
      repository_rows = datatable_service.repository_rows
                                         .preload(:repository_columns,
                                                  :created_by,
                                                  repository_cells: { value: @repository.cell_preload_includes })
      rows_view = 'repository_rows/index'
    end
    @repository_rows = repository_rows.page(page).per(per_page)

    render rows_view
  end

  def create
    repository_row = RepositoryRow.find(params[:repository_row_id])
    repository = repository_row.repository
    return render_403 unless can_read_repository?(repository)

    ActiveRecord::Base.transaction do
      @my_module.my_module_repository_rows.create!(repository_row: repository_row, assigned_by: current_user)

      Activities::CreateActivityService.call(activity_type: :assign_repository_record,
                                             owner: current_user,
                                             team: @my_module.experiment.project.team,
                                             project: @my_module.experiment.project,
                                             subject: @my_module,
                                             message_items: { my_module: @my_module.id,
                                                              repository: repository.id,
                                                              record_names: repository_row.name })

      render json: {
        flash: t('my_modules.assigned_items.direct_assign.success')
      }
    end
  rescue StandardError => e
    Rails.logger.error e.message
    render json: {
      flash: t('my_modules.repository.flash.update_error')
    }, status: :bad_request
  end

  def update
    service = RepositoryRows::MyModuleAssignUnassignService.call(my_module: @my_module,
                                                                 repository: @repository,
                                                                 user: current_user,
                                                                 params: params)
    if service.succeed?
      flash = update_flash_message(service)
      status = :ok
    else
      flash = t('my_modules.repository.flash.update_error')
      status = :bad_request
    end

    render json: {
      flash: flash,
      rows_count: @my_module.repository_rows_count(@repository),
      assigned_count: service.assigned_rows_count,
      repository_id: @repository.repository_snapshots.find_by(selected: true)&.id || @repository.id
    }, status: status
  end

  def update_repository_records_modal
    modal = render_to_string(
      partial: 'my_modules/modals/update_repository_records_modal_content',
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
      partial: 'my_modules/modals/assign_repository_records_modal_content',
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
      html: render_to_string(
        partial: 'my_modules/repositories/full_view_table',
        locals: { include_stock_consumption: params[:include_stock_consumption] == 'true' }
      )
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
      RepositoryZipExportJob.perform_later(
        user_id: current_user.id,
        params: {
          repository_id: @repository.id,
          my_module_id: @my_module.id,
          header_ids: params[:header_ids]
        }
      )

      Activities::CreateActivityService.call(
        activity_type: :export_inventory_items_assigned_to_task,
        owner: current_user,
        subject: @my_module,
        team: @repository.team,
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
        partial: 'my_modules/repositories/consume_stock_modal_content'
      )
    }
  end

  def update_consumption
    module_repository_row = @my_module.my_module_repository_rows.find_by(id: params[:module_row_id])

    ActiveRecord::Base.transaction do
      current_stock = module_repository_row.stock_consumption
      module_repository_row.consume_stock(current_user, params[:stock_consumption], params[:comment])

      log_activity(module_repository_row, current_stock, params[:comment])
      protocol_consumption_notification(params[:comment], module_repository_row)
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

  def protocol_consumption_notification(comment, module_repository_row)
    smart_annotation_notification(
      old_text: nil,
      new_text: comment,
      subject: module_repository_row.repository_row,
      title: t('notifications.my_module_consumption_comment_annotation_title',
               repository_item: module_repository_row.repository_row.name,
               repository: @repository.name,
               user: current_user.full_name),
      message: t('notifications.my_module_consumption_comment_annotation_message_html',
                 project: link_to(@my_module.experiment.project.name, project_url(@my_module.experiment.project)),
                 experiment: link_to(@my_module.experiment.name, my_modules_experiment_url(@my_module.experiment)),
                 my_module: link_to(@my_module.name, protocols_my_module_url(@my_module)))
    )
  end

  def log_activity(module_repository_row, stock_consumption_was, comment)
    Activities::CreateActivityService
      .call(activity_type: :task_inventory_item_stock_consumed,
            owner: current_user,
            subject: @my_module,
            team: @repository.team,
            project: @my_module.project,
            message_items: {
              repository: @repository.id,
              repository_row: module_repository_row.repository_row_id,
              stock_consumption_was: stock_consumption_was || 0,
              unit: module_repository_row.repository_row.repository_stock_value.repository_stock_unit_item&.data || '',
              stock_consumption: module_repository_row.stock_consumption || 0,
              my_module: @my_module.id,
              comment: comment
            })
  end
end
