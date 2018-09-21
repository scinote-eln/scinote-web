class RepositoryRowsController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  before_action :load_info_modal_vars, only: :show
  before_action :load_vars, only: %i(edit update)
  before_action :load_repository,
                only: %i(create
                         delete_records
                         index
                         copy_records
                         available_rows)
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions,
                only: %i(edit update delete_records copy_records)

  def index
    @draw = params[:draw].to_i
    per_page = params[:length] == '-1' ? 100 : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    records = RepositoryDatatableService.new(@repository,
                                             params,
                                             current_user)
    @assigned_rows = records.assigned_rows
    @repository_row_count = records.repository_rows.length
    @columns_mappings = records.mappings
    @repository_rows = records.repository_rows.page(page).per(per_page)
  end

  def create
    record = RepositoryRow.new(repository: @repository,
                               created_by: current_user,
                               last_modified_by: current_user)
    errors = { default_fields: [],
               repository_cells: [] }

    record.transaction do
      record.name = record_params[:repository_row_name] unless record_params[:repository_row_name].blank?
      errors[:default_fields] = record.errors.messages unless record.save
      if cell_params
        cell_params.each do |key, value|
          next if create_cell_value(record, key, value, errors).nil?
        end
      end
      raise ActiveRecord::Rollback if errors[:repository_cells].any?
    end

    respond_to do |format|
      format.json do
        if errors[:default_fields].empty? && errors[:repository_cells].empty?
          render json: { id: record.id,
                         flash: t('repositories.create.success_flash',
                                  record: escape_input(record.name),
                         repository: escape_input(@repository.name)) },
                 status: :ok
        else
          render json: errors,
          status: :bad_request
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'repositories/repository_row_info_modal.html.erb'
          )
        }
      end
    end
  end

  def edit
    json = {
      repository_row: {
        name: escape_input(@record.name),
        repository_cells: {},
        repository_column_items: fetch_columns_list_items
      }
    }

    # Add custom cells ids as key (easier lookup on js side)
    @record.repository_cells.each do |cell|
      if cell.value_type == 'RepositoryAssetValue'
        cell_value = cell.value.asset
      else
        cell_value = escape_input(cell.value.data)
      end

      json[:repository_row][:repository_cells][cell.repository_column_id] = {
        repository_cell_id: cell.id,
        cell_column_id: cell.repository_column.id, # needed for mappings
        value: cell_value,
        type: cell.value_type,
        list_items: fetch_list_items(cell)
      }
    end

    respond_to do |format|
      format.html
      format.json { render json: json }
    end
  end

  def update
    errors = {
      default_fields: [],
      repository_cells: []
    }

    @record.transaction do
      @record.name = record_params[:repository_row_name].blank? ? nil : record_params[:repository_row_name]
      errors[:default_fields] = @record.errors.messages unless @record.save
      if cell_params
        cell_params.each do |key, value|
          existing = @record.repository_cells.detect do |c|
            c.repository_column_id == key.to_i
          end
          if existing
            # Cell exists and new value present, so update value
            if existing.value_type == 'RepositoryListValue'
              item = RepositoryListItem.where(
                repository_column: existing.repository_column
              ).find(value) unless value == '-1'
              if item
                existing.value.update_attribute(
                  :repository_list_item_id, item.id
                )
              else
                existing.delete
              end
            elsif existing.value_type == 'RepositoryAssetValue'
              existing.value.destroy && next if remove_file_columns_params.include?(key)
              if existing.value.asset.update(file: value)
                existing.value.asset.created_by = current_user
                existing.value.asset.last_modified_by = current_user
                existing.value.asset.post_process_file(current_team)
              else
                errors[:repository_cells] << {
                  "#{existing.repository_column_id}": { data: existing.value.asset.errors.messages[:file].first }
                }
              end
            else
              existing.value.destroy && next if value == ''
              existing.value.data = value
              if existing.value.save
                record_annotation_notification(@record, existing)
              else
                errors[:repository_cells] << {
                  "#{existing.repository_column_id}":
                  existing.value.errors.messages
                }
              end
            end
          else
            next if value == ''
            # Looks like it is a new cell, so we need to create new value, cell
            # will be created automatically
            next if create_cell_value(@record, key, value, errors).nil?
          end
        end
      else
        @record.repository_cells.each { |c| c.value.destroy }
      end
      raise ActiveRecord::Rollback if errors[:repository_cells].any?
    end

    respond_to do |format|
      format.json do
        if errors[:default_fields].empty? && errors[:repository_cells].empty?
          # Row sucessfully updated, so sending response to client
          render json: {
            id: @record.id,
            flash: t(
              'repositories.update.success_flash',
              record: escape_input(@record.name),
              repository: escape_input(@repository.name)
            )
          },
          status: :ok
        else
          # Errors
          render json: errors,
          status: :bad_request
        end
      end
    end
  end

  def create_cell_value(record, key, value, errors)
    column = @repository.repository_columns.detect do |c|
      c.id == key.to_i
    end

    save_successful = false
    if column.data_type == 'RepositoryListValue'
      return if value == '-1'
      # check if item exists else revert the transaction
      list_item = RepositoryListItem.where(repository_column: column)
                                    .find(value)
      cell_value = RepositoryListValue.new(
        repository_list_item_id: list_item.id,
        created_by: current_user,
        last_modified_by: current_user,
        repository_cell_attributes: {
          repository_row: record,
          repository_column: column
        }
      )
      save_successful = list_item && cell_value.save
    elsif column.data_type == 'RepositoryAssetValue'
      return if value.blank?
      asset = Asset.new(file: value,
                        created_by: current_user,
                        last_modified_by: current_user,
                        team: current_team)
      if asset.save
        asset.post_process_file(current_team)
      else
        errors[:repository_cells] << {
          "#{column.id}": { data: asset.errors.messages[:file].first }
        }
      end
      cell_value = RepositoryAssetValue.new(
        asset: asset,
        created_by: current_user,
        last_modified_by: current_user,
        repository_cell_attributes: {
          repository_row: record,
          repository_column: column
        }
      )
      save_successful = cell_value.save
    else
      cell_value = RepositoryTextValue.new(
        data: value,
        created_by: current_user,
        last_modified_by: current_user,
        repository_cell_attributes: {
          repository_row: record,
          repository_column: column
        }
      )
      if (save_successful = cell_value.save)
        record_annotation_notification(record,
                                       cell_value.repository_cell)
      end
    end

    unless save_successful
      errors[:repository_cells] << {
        "#{column.id}": cell_value.errors.messages
      }
    end
  end

  def delete_records
    deleted_count = 0
    if selected_params
      selected_params.each do |row_id|
        row = @repository.repository_rows.find_by_id(row_id)
        if row && can_manage_repository_rows?(@repository.team)
          row.destroy && deleted_count += 1
        end
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
      respond_to do |format|
        color = deleted_count.zero? ? 'info' : 'success'
        format.json { render json: { flash: flash, color: color }, status: :ok }
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            flash: t('repositories.destroy.no_records_selected_flash')
          }, status: :bad_request
        end
      end
    end
  end

  def copy_records
    duplicate_service = RepositoryActions::DuplicateRows.new(
      current_user, @repository, params[:selected_rows]
    )
    duplicate_service.call
    render json: {
      flash: t('repositories.copy_records_report',
               number: duplicate_service.number_of_duplicated_items)
    }, status: :ok
  end

  def available_rows
    if @repository.repository_rows.empty?
      no_items_string =
        "#{t('projects.reports.new.save_PDF_to_inventory_modal.no_items')} " \
        "#{link_to(t('projects.reports.new.save_PDF_to_inventory_modal.here'),
                   repository_path(@repository),
                   data: { 'no-turbolink' => true })}"
      render json: { no_items: no_items_string },
                   status: :ok
    else
      render json: { results: load_available_rows(search_params[:q]) },
                   status: :ok
    end
  end

  private

  include StringUtility
  AvailableRepositoryRow = Struct.new(:id, :name, :has_file_attached)

  def load_info_modal_vars
    @repository_row = RepositoryRow.eager_load(:created_by, repository: [:team])
                                   .find_by_id(params[:id])
    @assigned_modules = MyModuleRepositoryRow.eager_load(
      my_module: [{ experiment: :project }]
    ).where(repository_row: @repository_row)
    render_404 and return unless @repository_row
    render_403 unless can_read_team?(@repository_row.repository.team)
  end

  def load_vars
    @repository = Repository.eager_load(:repository_columns)
                            .find_by_id(params[:repository_id])
    @record = RepositoryRow.eager_load(:repository_columns)
                           .find_by_id(params[:id])
    render_404 unless @repository && @record
  end

  def load_repository
    @repository = Repository.find_by_id(params[:repository_id])
    render_404 unless @repository
    render_403 unless can_read_team?(@repository.team)
  end

  def check_create_permissions
    render_403 unless can_create_repository_rows?(@repository.team)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_rows?(@repository.team)
  end

  def record_params
    params.permit(:repository_row_name).to_h
  end

  def cell_params
    params.permit(repository_cells: {}).to_h[:repository_cells]
  end

  def remove_file_columns_params
    JSON.parse(params.fetch(:remove_file_columns) { '[]' })
  end

  def selected_params
    params.permit(selected_rows: []).to_h[:selected_rows]
  end

  def load_available_rows(query)
    @repository.repository_rows
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
    table_url = params.fetch(:request_url) { :request_url_must_be_present }
    smart_annotation_notification(
      old_text: (old_text if old_text),
      new_text: cell.value.data,
      title: t('notifications.repository_annotation_title',
               user: current_user.full_name,
               column: cell.repository_column.name,
               record: record.name,
               repository: record.repository),
      message: t('notifications.repository_annotation_message_html',
                 record: link_to(record.name, table_url),
                 column: link_to(cell.repository_column.name, table_url))
    )
  end

  def fetch_list_items(cell)
    return [] if cell.value_type != 'RepositoryListValue'
    RepositoryListItem.where(repository: @repository)
                      .where(repository_column: cell.repository_column)
                      .limit(Constants::SEARCH_LIMIT)
                      .pluck(:id, :data)
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
      }
    end
    collection
  end
end
