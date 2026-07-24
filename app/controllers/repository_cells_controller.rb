# frozen_string_literal: true

class RepositoryCellsController < ApplicationController
  before_action :load_repository
  before_action :load_repository_row
  before_action :load_repository_column
  before_action :check_manage_permissions

  def update
    value = params[:value]
    @cell = @repository_row.repository_cells.find_by(repository_column: @repository_column)

    ActiveRecord::Base.transaction do
      if @cell.present? && value.blank?
        @repository_row.update!(last_modified_by: current_user)
        @cell.destroy!
        @cell = nil
        log_activity
      elsif @cell.blank? && value.present?
        @cell = RepositoryCell.create_with_value!(@repository_row, @repository_column, value, current_user)
        log_activity
      elsif @cell.present? && @cell.value.data_different?(value)
        @cell.value.update_data!(value, current_user)
        log_activity
      end
    end

    return head :no_content if @cell.blank?

    render json: @cell.reload, serializer: RepositoryCellSerializer
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def load_repository
    @repository = Repository.readable_by_user(current_user).find_by(id: params[:repository_id])

    render_404 unless @repository
  end

  def load_repository_row
    @repository_row = @repository.repository_rows.find_by(id: params[:repository_row_id])

    render_404 unless @repository_row
  end

  def load_repository_column
    @repository_column = @repository.repository_columns.find_by(id: params[:repository_column_id])

    render_404 unless @repository_column
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_rows?(@repository)
  end

  def log_activity
    Activities::CreateActivityService.call(
      activity_type: :edit_item_inventory,
      owner: current_user,
      subject: @repository_row,
      team: @repository.team,
      message_items: { repository_row: @repository_row.id, repository: @repository.id }
    )
  end
end
