class RepositoryRowsController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include MyModulesHelper
  include RepositoryDatatableHelper

  before_action :load_repository, except: %i(show print rows_to_print print_zpl validate_label_template_columns)
  before_action :load_repository_or_snapshot, only: %i(show print rows_to_print print_zpl
                                                       validate_label_template_columns)
  before_action :load_repository_row, only: %i(show update update_cell assigned_task_list
                                               active_reminder_repository_cells relationships)
  before_action :load_repository_rows, only: %i(print rows_to_print print_zpl validate_label_template_columns)

  before_action :check_read_permissions, except: %i(create update update_cell delete_records
                                                    copy_records archive_records restore_records)
  before_action :check_snapshotting_status, only: %i(create update delete_records copy_records)
  before_action :check_create_permissions, only: :create
  before_action :check_delete_permissions, only: %i(delete_records archive_records restore_records)
  before_action :check_manage_permissions, only: %i(update update_cell copy_records)

  def index
    @draw = params[:draw].to_i
    per_page = params[:length] == '-1' ? 100 : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositoryDatatableService.new(@repository, params, current_user)

    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings
    @repository_rows = datatable_service.repository_rows
                                        .preload(:repository_columns,
                                                 :created_by,
                                                 :archived_by,
                                                 repository_cells: { value: @repository.cell_preload_includes })
                                        .page(page)
                                        .per(per_page)

    @repository_rows = @repository_rows.where(archived: params[:archived]) unless @repository.archived?
  rescue RepositoryFilters::ColumnNotFoundException
    render json: { custom_error: I18n.t('repositories.show.repository_filter.errors.column_not_found') }
  rescue RepositoryFilters::ValueNotFoundException
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
          @my_module_assign_error = if !can_assign_my_module_repository_rows?(@my_module)
                                      I18n.t('repository_row.modal_info.assign_to_task_error.no_access')
                                    elsif @repository_row.my_modules.where(id: @my_module.id).any?
                                      I18n.t('repository_row.modal_info.assign_to_task_error.already_assigned')
                                    end
        end

        @assigned_modules = @repository_row.my_modules
                                           .joins(experiment: :project)
                                           .joins(:my_module_repository_rows)
                                           .select('my_module_repository_rows.created_at, my_modules.*')
                                           .order('my_module_repository_rows.created_at': :desc)
                                           .distinct
        @viewable_modules = @assigned_modules.viewable_by_user(current_user, current_user.teams)
        @reminders_present = @repository_row.repository_cells.with_active_reminder(@current_user).any?
      end
    end
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

      render json: { id: service.repository_row.id, flash: t('repositories.create.success_flash',
                                                             record: escape_input(repository_row.name),
                                                             repository: escape_input(@repository.name)) },
             status: :ok
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

      render json: {
        id: @repository_row.id,
        flash: t(
          'repositories.update.success_flash',
          record: escape_input(@repository_row.name),
          repository: escape_input(@repository.name)
        )
      }, status: :ok
    else
      render json: row_update.errors, status: :bad_request
    end
  end

  def update_cell
    return render_422(t('.invalid_params')) if
      update_params['repository_row'].present? && update_params['repository_cells'].present?
    return render_422(t('.invalid_params')) if
      update_params['repository_cells'] && update_params['repository_cells'].size != 1

    row_cell_update =
      RepositoryRows::UpdateRepositoryRowService.call(
        repository_row: @repository_row, user: current_user, params: update_params
      )

    if row_cell_update.succeed?
      if row_cell_update.record_updated
        log_activity(:edit_item_field_inventory, @repository_row,
                     { repository_row: @repository_row.id,
                       repository_column: update_params['repository_cells']&.keys&.first ||
                       I18n.t('repositories.table.row_name') })
      end
      @reminders_present = @repository_row.repository_cells.with_active_reminder(@current_user).any?

      return render json: { name: @repository_row.name } if update_params['repository_row'].present?

      column = row_cell_update.column
      cell = row_cell_update.cell&.reload || row_cell_update.cell
      data = { value_type: column.data_type, id: column.id, value: nil }

      return render json: data if cell.blank?

      data['hasActiveReminders'] = @reminders_present
      data.merge! serialize_repository_cell_value(cell,
                                                  @repository.team,
                                                  @repository,
                                                  reminders_enabled: @reminders_present)
      render json: data
    else
      render json: row_cell_update.errors, status: :bad_request
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
    viewable_modules = assigned_modules.viewable_by_user(current_user, current_user.teams)
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
    reminder_cells = @repository_row.repository_cells.with_active_reminder(current_user).distinct
    render json: {
      html: render_to_string(partial: 'shared/repository_row_reminder', locals: {
                               reminders: reminder_cells
                             })
    }
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::RepositoryRowsService.new(
          current_user,
          repository_row_ids: params[:repository_row_ids].split(',')
        ).actions
    }
  end

  def relationships
    render json: {
      repository_row: RepositoryRowSerializer.new(@repository_row),
      parents: @repository_row.parent_repository_rows.map { |r| RepositoryRowSerializer.new(r) },
      children: @repository_row.child_repository_rows.map { |r| RepositoryRowSerializer.new(r) }
    }
  end

  private

  include StringUtility
  AvailableRepositoryRow = Struct.new(:id, :name, :has_file_attached)

  def load_repository
    @repository = Repository.accessible_by_teams(current_team)
                            .eager_load(:repository_columns)
                            .find_by(id: params[:repository_id])
    render_404 unless @repository
  end

  def load_repository_or_snapshot
    @repository = Repository.accessible_by_teams(current_team).find_by(id: params[:repository_id]) ||
                  RepositorySnapshot.find_by(id: params[:repository_id])
    return render_404 unless @repository
  end

  def load_repository_row
    @repository_row = @repository.repository_rows.eager_load(:repository_columns).find_by(id: params[:id])
    render_404 unless @repository_row
  end

  def load_repository_rows
    @repository_rows = @repository.repository_rows.eager_load(:repository_columns).where(id: params[:row_ids])

    render_404 if @repository_rows.blank?
  end

  def check_read_permissions
    render_403 unless can_read_repository?(@repository)
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

  def record_annotation_notification(record, cell, old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: cell.value.data,
      subject: cell.repository_column.repository,
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
    params.permit(repository_row: :name, repository_cells: {}).to_h
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
