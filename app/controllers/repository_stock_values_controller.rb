# frozen_string_literal: true

class RepositoryStockValuesController < ApplicationController
  before_action :load_vars
  before_action :check_manage_permissions

  def new
    render json: {
      html: render_to_string(
        partial: 'repository_stock_values/manage_modal_content',
        locals: {
          repository_row: @repository_row,
          repository_stock_column: @repository_column,
          unit_items: @repository_column.repository_stock_unit_items,
          repository_stock_value: RepositoryStockValue.new
        }
      )
    }
  end

  def edit
    render json: {
      html: render_to_string(
        partial: 'repository_stock_values/manage_modal_content',
        locals: {
          repository_row: @repository_row,
          repository_stock_column: @repository_column,
          unit_items: @repository_column.repository_stock_unit_items,
          repository_stock_value: @repository_stock_value
        }
      )
    }
  end

  def create_or_update
    if @repository_stock_value # update
      ActiveRecord::Base.transaction do
        @repository_stock_value.update_stock_with_ledger!(
          repository_stock_value_params[:amount],
          @repository,
          repository_stock_value_params[:comment].presence
        )
        @repository_stock_value.repository_stock_unit_item =
          @repository_column.repository_stock_unit_items.find(repository_stock_value_params[:unit_item_id])
        @repository_stock_value.update_data!(repository_stock_value_params[:amount], current_user)
      end
    else
      ActiveRecord::Base.transaction do # create
        repository_cell = @repository_row.repository_cells.create(repository_column: @repository_column)
        @repository_stock_value = RepositoryStockValue.new_with_payload(
          repository_stock_value_params[:amount],
          repository_cell: repository_cell,
          created_by: current_user,
          last_modified_by: current_user,
          repository_stock_unit_item: @repository_column.repository_stock_unit_items
                                                        .find(repository_stock_value_params[:unit_item_id])
        )
        @repository_stock_value.save!
        @repository_stock_value.update_stock_with_ledger!(
          repository_stock_value_params[:amount],
          @repository,
          repository_stock_value_params[:comment].presence
        )
      end
    end
  end

  private

  def load_vars
    @repository = Repository.find(params[:repository_id])
    @repository_row = @repository.repository_rows.find(params[:id])
    @repository_column = @repository.repository_columns.find_by(data_type: 'RepositoryStockValue')
    @repository_stock_value = @repository_row.repository_stock_value
  end

  def check_manage_permissions
    render_403 unless can_manage_repository?(@repository)
  end

  def repository_stock_value_params
    params.require(:repository_stock_value).permit(:unit_item_id, :amount, :comment)
  end
end
