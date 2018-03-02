class RepositoryRowsController < ApplicationController
  include InputSanitizeHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  before_action :load_info_modal_vars, only: :show
  before_action :load_vars, only: %i(edit update)
  before_action :load_repository, only: %i(create delete_records)
  before_action :check_create_permissions, only: :create
  before_action :check_edit_permissions, only: %i(edit update)
  before_action :check_destroy_permissions, only: :delete_records

  def create
    record = RepositoryRow.new(repository: @repository,
                               created_by: current_user,
                               last_modified_by: current_user)
    errors = { default_fields: [],
               repository_cells: [] }

    record.transaction do
      record.name = record_params[:name] unless record_params[:name].blank?
      errors[:default_fields] = record.errors.messages unless record.save
      if cell_params
        cell_params.each do |key, value|
          column = @repository.repository_columns.detect do |c|
            c.id == key.to_i
          end
          cell_value = RepositoryTextValue.new(
            data: value,
            created_by: current_user,
            last_modified_by: current_user,
            repository_cell_attributes: {
              repository_row: record,
              repository_column: column
            }
          )
          if cell_value.save
            record_annotation_notification(record, cell_value.repository_cell)
          else
            errors[:repository_cells] << {
              "#{column.id}": cell_value.errors.messages
            }
          end
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
        repository_cells: {}
      }
    }

    # Add custom cells ids as key (easier lookup on js side)
    @record.repository_cells.each do |cell|
      json[:repository_row][:repository_cells][cell.repository_column_id] = {
        repository_cell_id: cell.id,
        value: escape_input(cell.value.data)
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
      @record.name = record_params[:name].blank? ? nil : record_params[:name]
      errors[:default_fields] = @record.errors.messages unless @record.save
      if cell_params
        cell_params.each do |key, value|
          existing = @record.repository_cells.detect do |c|
            c.repository_column_id == key.to_i
          end
          if existing
            # Cell exists and new value present, so update value
            existing.value.data = value
            if existing.value.save
              record_annotation_notification(@record, existing)
            else
              errors[:repository_cells] << {
                "#{existing.repository_column_id}":
                existing.value.errors.messages
              }
            end
          else
            # Looks like it is a new cell, so we need to create new value, cell
            # will be created automatically
            column = @repository.repository_columns.detect do |c|
              c.id == key.to_i
            end
            cell_value = RepositoryTextValue.new(
              data: value,
              created_by: current_user,
              last_modified_by: current_user,
              repository_cell_attributes: {
                repository_row: @record,
                repository_column: column
              }
            )
            if cell_value.save
              record_annotation_notification(@record,
                                             cell_value.repository_cell)
            else
              errors[:repository_cells] << {
                "#{column.id}": cell_value.errors.messages
              }
            end
          end
        end
        # Clean up empty cells, not present in updated record
        @record.repository_cells.each do |cell|
          cell.value.destroy unless cell_params
                                    .key?(cell.repository_column_id.to_s)
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

  def delete_records
    deleted_count = 0
    if selected_params
      selected_params.each do |row_id|
        row = @repository.repository_rows.find_by_id(row_id)
        if row && can_update_or_delete_repository_row?(row)
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

  private

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
  end

  def check_create_permissions
    render_403 unless can_manage_repository_rows?(@repository.team)
  end

  def check_edit_permissions
    render_403 unless can_update_or_delete_repository_row?(@record)
  end

  def check_destroy_permissions
    render_403 unless can_manage_repository_rows?(@repository.team)
  end

  def record_params
    params.require(:repository_row).permit(:name).to_h
  end

  def cell_params
    params.permit(repository_cells: {}).to_h[:repository_cells]
  end

  def selected_params
    params.permit(selected_rows: []).to_h[:selected_rows]
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
end
