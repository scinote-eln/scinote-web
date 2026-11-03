class RepositoryRowsController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include MyModulesHelper
  include StorageLocationsHelper
  include EquipmentBookingHelper
  include RepositoryColumnsHelper

  before_action :load_repository, except: %i(show print rows_to_print print_zpl validate_label_template_columns)
  before_action :load_repository_or_snapshot, only: %i(show print rows_to_print print_zpl
                                                       validate_label_template_columns)
  before_action :load_repository_row, only: %i(show update assigned_task_list assigned_counters
                                               active_reminder_repository_cells relationships equipment_booking_events
                                               storage_locations assigned_modules)
  before_action :load_repository_rows, only: %i(print rows_to_print print_zpl validate_label_template_columns)

  before_action :check_read_permissions, except: %i(create update delete_records
                                                    copy_records archive_records restore_records)
  before_action :check_snapshotting_status, only: %i(create update delete_records copy_records)
  before_action :check_create_permissions, only: :create
  before_action :check_delete_permissions, only: :delete_records
  before_action :check_manage_permissions, only: %i(update archive_records restore_records copy_records)

  def index_ag
    repository_rows = Lists::RepositoryRowsService.new(@repository, params, user: current_user, filter_by_view_mode: true).call.load

    total_count = if @repository.archived?
                    @repository.repository_rows.count
                  elsif params[:view_mode] == 'archived'
                    @repository.repository_rows.archived.count
                  else
                    @repository.repository_rows.active.count
                  end

    can_manage_repository_rows = if params[:view_mode] == 'archived'
                                   false
                                 else
                                   can_manage_repository_rows?(@repository)
                                 end

    filtered_count = repository_rows.take&.filtered_count.to_i
    total_pages = (filtered_count.to_f / params[:per_page].to_i).ceil

    render json: repository_rows,
           each_serializer: Lists::RepositoryRowSerializer,
           user: current_user,
           can_read_repository: can_read_repository?(@repository),
           with_reminders: Repository.reminders_enabled?,
           with_stock_management: @repository.has_stock_management?,
           can_manage_stock: can_manage_repository_stock?(@repository),
           can_manage_repository_rows: can_manage_repository_rows,
           meta: {
             total_pages: total_pages,
             total_count: total_count,
             filtered_count: filtered_count
           }
  rescue Lists::RepositoryFilters::ColumnNotFoundException
    render json: { custom_error: I18n.t('repositories.show.repository_filter.errors.column_not_found') }
  rescue Lists::RepositoryFilters::ValueNotFoundException
    render json: { custom_error: I18n.t('repositories.show.repository_filter.errors.value_not_found') }
  end

  def show
    respond_to do |format|
      format.html do
        redirect_to repository_path(@repository)
      end

      format.json do
        @my_module = if params[:my_module_id].present?
                       MyModule.repository_row_assignable_by_user(current_user).find_by(id: params[:my_module_id])
                     end
        return render_403 if @my_module && !can_read_my_module?(@my_module)

        if @my_module
          already_assigned = @repository_row.my_modules.where(id: @my_module.id).any?
          @assign_to_current_task = {
            url: my_module_repositories_path(@my_module.id),
            disabled: !can_assign_my_module_repository_rows?(@my_module) || already_assigned
          }
        end

        @repository ||= Repository.new(id: @repository_row.repository_id)
        @repository_row.repository = @repository

        # matches index_ag's own `view_mode == 'archived' -> can_manage_repository_rows = false`:
        # an archived row's custom columns/stock are read-only in the table, so they must be here too
        editable_context = @repository_row.snapshot_at.nil? && !@repository_row.archived? &&
                            @repository.is_a?(Repository) && !@repository.is_a?(SoftLockedRepository)

        @row = Lists::RepositoryRowSerializer.new(
          @repository_row,
          scope: current_user,
          scope_name: :current_user,
          user: current_user,
          can_manage_repository_rows: editable_context && can_manage_repository_rows?(@repository),
          with_reminders: Repository.reminders_enabled?,
          with_stock_management: @repository.has_stock_management?,
          can_manage_stock: editable_context && can_manage_repository_stock?(@repository)
        ).as_json.merge(id: @repository_row.id)

        @column_defs = repository_columns_ordered_by_state(@repository_row).map do |column|
          RepositoryColumnSerializer.new(column).as_json.merge(id: column.id)
        end
      end
    end
  end

  def assigned_counters
    assigned_my_modules_count, assigned_experiments_count, assigned_projects_count =
      @repository_row.my_module_repository_rows
                     .joins(my_module: :experiment)
                     .pick(Arel.sql('COUNT(DISTINCT my_module_repository_rows.id) AS "assigned_my_modules_count"'),
                           Arel.sql('COUNT(DISTINCT my_modules.experiment_id) AS "assigned_experiments_count"'),
                           Arel.sql('COUNT(DISTINCT experiments.project_id) AS "assigned_projects_count"'))
    render json: {
      tasks: assigned_my_modules_count,
      experiments: assigned_experiments_count,
      projects: assigned_projects_count
    }
  end

  def create
    service = RepositoryRows::CreateRepositoryRowService
              .call(repository: @repository, user: current_user, params: update_params)

    if service.succeed?
      repository_row = service.repository_row
      log_activity(:create_item_inventory, repository_row, { repository_row: repository_row.id,
                                                             repository: @repository.id })
      repository_row.repository_cells.where(value_type: 'RepositoryTextValue').each do |repository_cell|
        record_annotation_notification(repository_row, repository_cell)
      end

      if update_params[:my_module_id].present?
        my_module = MyModule.readable_by_user(current_user, current_team).find_by(id: update_params[:my_module_id])

        return render_403 unless my_module.present? && can_read_my_module?(my_module)

        ActiveRecord::Base.transaction do
          service_assign = RepositoryRows::MyModuleAssignUnassignService.call(
            my_module: my_module,
            repository: @repository,
            user: current_user,
            params: { rows_to_assign: [repository_row.id] }
          )

          render json: service_assign.errors, status: :bad_request unless service_assign.succeed?
        end
      end

      render json: repository_row,
             serializer: Lists::RepositoryRowSerializer,
             user: current_user,
             can_read_repository: can_read_repository?(@repository),
             with_reminders: Repository.reminders_enabled?,
             with_stock_management: @repository.has_stock_management?,
             can_manage_stock: can_manage_repository_stock?(@repository),
             can_manage_repository_rows: can_manage_repository_rows?(@repository)
    else
      render json: service.errors, status: :bad_request
    end
  end

  def validate_label_template_columns
    label_template = LabelTemplate.where(team_id: current_team.id).find(params[:label_template_id])

    label_code = LabelTemplates::RepositoryRowService.new(label_template, @repository_rows.first).render
    if label_code[:error].empty?
      render json: { label_code: label_code[:label] }
    else
      render json: { error: label_code[:error].first, label_code: label_code[:label] }, status: :unprocessable_entity
    end
  end

  def print_zpl
    label_template = LabelTemplate.find_by(id: params[:label_template_id])
    labels = @repository_rows.flat_map do |repository_row|
      LabelTemplates::RepositoryRowService.new(label_template,
                                               repository_row).render[:label]
    end

    render(
      json: {
        html:
          render_to_string(
            partial: 'label_printers/print_zebra_progress_modal'
          ),
        labels: labels
      }
    )
  end

  def equipment_booking_events
    page = params[:page]&.to_i || 1

    events = @repository_row.calendar_events

    events = case params[:direction]
             when 'past'
               events.where('end_date < ? OR end_datetime < ?', Time.zone.today, Time.current)
                     .order(Arel.sql('COALESCE(end_date, end_datetime) DESC'))
             when 'future'
               events.where('end_date >= ? OR end_datetime >= ?', Time.zone.today, Time.current)
                     .order(Arel.sql('COALESCE(start_date, start_datetime) ASC'))
             else
               events.order(Arel.sql('COALESCE(start_date, start_datetime) DESC'))
             end

    events = events.page(page).per(3)

    render json: events,
           each_serializer: CalendarEventSerializer,
           meta: {
             has_next_page: events.next_page.present?
           }
  end

  def rows_to_print
    render json: @repository_rows, each_serializer: RepositoryRowSerializer, user: current_user
  end

  def print
    # reset all potential error states for printers and discard all jobs

    # rubocop:disable Rails/SkipsModelValidations
    LabelPrinter.update_all(status: :ready, current_print_job_ids: [])
    # rubocop:enable Rails/SkipsModelValidations

    label_printer = LabelPrinter.find(params[:label_printer_id])
    label_template = LabelTemplate.find_by(id: params[:label_template_id])

    job_ids = @repository_rows.flat_map do |repository_row|
      LabelPrinters::PrintJob.perform_later(
        label_printer,
        LabelTemplates::RepositoryRowService.new(label_template,
                                                 repository_row).render[:label],
        params[:copies].to_i
      ).job_id
    end

    label_printer.update!(current_print_job_ids: job_ids * params[:copies].to_i)

    render json: {
      html: render_to_string(
        partial: 'label_printers/print_progress_modal',
        formats: :html,
        locals: { starting_item_count: label_printer.current_print_job_ids.length,
                  label_printer: label_printer }
      )
    }
  end

  def update
    row_update = RepositoryRows::UpdateRepositoryRowService
                 .call(repository_row: @repository_row, user: current_user, params: update_params)

    if row_update.succeed?
      if row_update.record_updated
        log_activity(:edit_item_inventory, @repository_row, { repository_row: @repository_row.id,
                                                              repository: @repository.id })
        @repository_row.repository_cells.where(value_type: 'RepositoryTextValue').each do |repository_cell|
          record_annotation_notification(@repository_row, repository_cell)
        end
      end

      render json: @repository_row,
             serializer: Lists::RepositoryRowSerializer,
             user: current_user,
             can_read_repository: can_read_repository?(@repository),
             with_reminders: Repository.reminders_enabled?,
             with_stock_management: @repository.has_stock_management?,
             can_manage_stock: can_manage_repository_stock?(@repository),
             can_manage_repository_rows: can_manage_repository_rows?(@repository)
    else
      render json: row_update.errors, status: :bad_request
    end
  end

  def delete_records
    deleted_count = 0
    if selected_params
      selected_params.each do |row_id|
        row = @repository.repository_rows.find_by(id: row_id)
        next unless row && can_manage_repository_rows?(@repository)

        log_activity(:delete_item_inventory, row, { repository_row: row.id, repository: @repository.id })
        row.destroy && deleted_count += 1
      end
      if deleted_count.zero?
        flash = t('repositories.destroy.no_deleted_records_flash',
                  other_records_number: selected_params.count)
      elsif deleted_count != selected_params.count
        not_deleted_count = selected_params.count - deleted_count
        flash = t('repositories.destroy.contains_other_records_flash',
                  records_number: deleted_count,
                  other_records_number: not_deleted_count)
      else
        flash = t('repositories.destroy.success_flash',
                  records_number: deleted_count)
      end
      color = deleted_count.zero? ? 'info' : 'success'
      render json: { flash: flash, color: color }, status: :ok
    else
      render json: {
        flash: t('repositories.destroy.no_records_selected_flash')
      }, status: :bad_request
    end
  end

  def copy_records
    duplicate_service = RepositoryActions::DuplicateRows.new(
      current_user, @repository, selected_rows_in_repo_params
    )
    duplicate_service.call
    render json: {
      flash: t('repositories.copy_records_report',
               number: duplicate_service.number_of_duplicated_items)
    }, status: :ok
  end

  def available_rows
    if @repository.repository_rows.active.blank?
      no_items_string =
        "#{t('projects.reports.new.save_PDF_to_inventory_modal.no_items')} " \
        "#{link_to(t('projects.reports.new.save_PDF_to_inventory_modal.here'),
                   repository_path(@repository),
                   data: { 'no-turbolink' => true })}"
      render json: { no_items: no_items_string }, status: :unprocessable_entity
    else
      render json: { results: load_available_rows }, status: :ok
    end
  end

  def assigned_task_list
    assigned_modules = @repository_row.my_modules.joins(experiment: :project)
                                      .where_attributes_like(
                                        ['my_modules.name', 'experiments.name', 'projects.name'],
                                        params[:query],
                                        whole_phrase: true
                                      )
    viewable_modules = assigned_modules.readable_by_user(current_user, current_user.teams)
    private_modules_number = assigned_modules.where.not(id: viewable_modules).count
    render json: {
      html: render_to_string(partial: 'shared/my_modules_list_partial', locals: {
                               my_modules: viewable_modules,
                               private_modules_number: private_modules_number
                             })
    }
  end

  def reminder_repository_cells
    render json: @repository_row.repository_cells.with_active_reminder(current_user)
  end

  def archive_records
    service = RepositoryActions::ArchiveRowsService.call(repository: @repository,
                                                         repository_rows: selected_rows_in_repo_params,
                                                         user: current_user,
                                                         team: current_team)

    if service.succeed?
      render json: { flash: t('repositories.archive_records.success_flash', repository: escape_input(@repository.name)) }
    else
      render json: { error: service.error_message }, status: :unprocessable_entity
    end
  end

  def restore_records
    service = RepositoryActions::RestoreRowsService.call(repository: @repository,
                                                         repository_rows: selected_rows_in_repo_params,
                                                         user: current_user,
                                                         team: current_team)

    if service.succeed?
      render json: { flash: t('repositories.restore_records.success_flash', repository: escape_input(@repository.name)) }
    else
      render json: { error: service.error_message }, status: :unprocessable_entity
    end
  end

  def active_reminder_repository_cells
    @reminder_cells = @repository_row.repository_cells.with_active_reminder(current_user).distinct
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::RepositoryRowsService.new(
          current_user,
          repository_row_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
  end

  def relationships
    render json: {
      parents_count: @repository_row.parent_connections_count,
      children_count: @repository_row.child_connections_count,
      parents: serialize_connections(@repository_row.parent_connections.preload(parent: :repository)),
      children: serialize_connections(@repository_row.child_connections.preload(child: :repository)),
      row_connections: {
        inventories_url: repository_row_connections_repositories_url,
        inventory_items_url: repository_rows_repository_repository_row_repository_row_connections_path(@repository, @repository_row),
        create_url: repository_repository_row_repository_row_connections_url(@repository, @repository_row)
      }
    }
  end

  def storage_locations
    render json: {
      locations: @repository_row.storage_locations.distinct.map do |storage_location|
        readable = can_read_storage_location?(storage_location)

        {
          id: storage_location.id,
          readable: readable,
          name: readable ? storage_location.name : storage_location.code,
          metadata: storage_location.metadata,
          breadcrumbs: storage_location.breadcrumbs(readable: readable),
          positions: readable ? storage_location.storage_location_repository_rows.where(repository_row: @repository_row) : []
        }
      end,
      enabled: StorageLocation.storage_locations_enabled?,
      placeholder: storage_locations_placeholder
    }
  end

  def assigned_modules
    my_modules = @repository_row.my_modules.distinct
    viewable_my_modules = my_modules.readable_by_user(current_user, current_user.teams)
                                    .joins(:my_module_repository_rows)
                                    .select('my_module_repository_rows.created_at, my_modules.*')
                                    .order(my_module_repository_rows: { created_at: :desc })

    render json: {
      total_assigned_size: my_modules.size,
      viewable_modules: viewable_my_modules.map { |my_module| serialize_assigned_my_module_value(my_module) }
    }
  end

  private

  include StringUtility
  AvailableRepositoryRow = Struct.new(:id, :name, :has_file_attached)

  def load_repository
    @repository = Repository.readable_by_user(current_user).find_by(id: params[:repository_id])

    render_404 unless @repository
  end

  def load_repository_or_snapshot
    if params[:form_repository_rows_field_value_id]
      @form_repository_rows_field_value =
        FormRepositoryRowsFieldValue.find_by(id: params[:form_repository_rows_field_value_id])
    end

    @repository = Repository.readable_by_user(current_user).find_by(id: params[:repository_id]) ||
                  RepositorySnapshot.find_by(id: params[:repository_id])

    render_404 unless @form_repository_rows_field_value || @repository
  end

  def load_repository_row
    @repository_row = if @form_repository_rows_field_value
                        @form_repository_rows_field_value.reified_repository_row_by_id(params[:id])
                      else
                        @repository.repository_rows.preload(:repository_columns).find_by(id: params[:id])
                      end

    render_404 unless @repository_row
  end

  def load_repository_rows
    @repository_rows = @repository.repository_rows.preload(:repository_columns).where(id: params[:row_ids])

    render_404 if @repository_rows.blank?
  end

  def check_read_permissions
    if @form_repository_rows_field_value
      render_403 unless can_read_my_module?(
        @form_repository_rows_field_value.form_response.step.protocol.my_module
      )
    else
      render_403 unless can_read_repository?(@repository)
    end
  end

  def check_snapshotting_status
    return if @repository.repository_snapshots.provisioning.none?

    render json: {
      flash: t('repositories.index.snapshot_provisioning_in_progress')
    }, status: :unprocessable_entity
  end

  def check_create_permissions
    render_403 unless can_create_repository_rows?(@repository)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_rows?(@repository)
  end

  def check_delete_permissions
    render_403 unless can_delete_repository_rows?(@repository)
  end

  def remove_file_columns_params
    JSON.parse(params.fetch(:remove_file_columns) { '[]' })
  end

  def selected_params
    params.permit(selected_rows: []).to_h[:selected_rows]
  end

  # Selected rows in scope of current @repository
  def selected_rows_in_repo_params
    process_ids = params[:selected_rows].map(&:to_i).uniq
    @repository.repository_rows.where(id: process_ids).pluck(:id)
  end

  def load_available_rows
    @repository.repository_rows
               .active
               .includes(:repository_cells)
               .name_like(search_params[:q])
               .limit(Constants::SEARCH_LIMIT)
               .select(:id, :name)
               .collect do |row|
                 with_asset_cell = row.repository_cells.where(
                   'repository_cells.repository_column_id = ?',
                   search_params[:repository_column_id]
                 )
                 AvailableRepositoryRow.new(row.id,
                                            ellipsize(row.name, 75, 50),
                                            with_asset_cell.present?)
               end
  end

  def search_params
    params.permit(:q, :repository_id, :repository_column_id)
  end

  def serialize_connections(connections)
    connections.map do |connection|
      RepositoryRowConnectionSerializer.new(
        connection,
        repository_row: @repository_row,
        scope: current_user,
        scope_name: :current_user
      ).as_json
    end
  end

  def record_annotation_notification(record, cell, old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: cell.value.data,
      subject: cell.repository_row,
      title: t('notifications.repository_annotation_title',
               user: current_user.full_name,
               column: cell.repository_column.name,
               record: record.name,
               repository: record.repository.name),
      message: t('notifications.repository_annotation_message_html',
                 record: link_to(record.name, repository_url(@repository)),
                 column: link_to(cell.repository_column.name, repository_url(@repository)))
    )
  end

  def fetch_list_items(cell)
    return [] if cell.value_type != 'RepositoryListValue'
    RepositoryListItem.where(repository: @repository)
                      .where(repository_column: cell.repository_column)
                      .limit(Constants::SEARCH_LIMIT)
                      .pluck(:id, :data)
                      .map { |li| [li[0], escape_input(li[1])] }
  end

  def fetch_columns_list_items
    collection = []
    @repository.repository_columns
               .list_type
               .preload(:repository_list_items)
               .each do |column|
      collection << {
        column_id: column.id,
        list_items: column.repository_list_items
                          .limit(Constants::SEARCH_LIMIT)
                          .pluck(:id, :data)
                          .map { |li| [li[0], escape_input(li[1])] }
      }
    end
    collection
  end

  def update_params
    params.permit(:my_module_id, :is_output, repository_row: :name, repository_cells: {}).to_h
  end

  def log_activity(type_of, repository_row, message_items = {})
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: repository_row,
            team: @repository.team,
            message_items: message_items)
  end
end
