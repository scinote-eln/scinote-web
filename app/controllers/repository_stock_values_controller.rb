# frozen_string_literal: true

class RepositoryStockValuesController < ApplicationController
  include RepositoryDatatableHelper # for use of serialize_repository_cell_value method on stock update

  before_action :load_vars
  before_action :check_manage_permissions

  def new; end

  def edit; end

  def create_or_update
    ActiveRecord::Base.transaction do
      @repository_stock_value ? update! : create!

      log_activity(
        params[:operator],
        params[:change_amount],
        @repository_stock_value.repository_stock_unit_item.data,
        @repository_stock_value.amount,
        params[:repository_stock_value][:comment]
      )
    end

    render json: {
      stock_managable: true,
      stock_status: @repository_stock_value.status,
    }.merge(
      serialize_repository_cell_value(
        @repository_stock_value.repository_cell, current_team, @repository,
        reminders_enabled: Repository.reminders_enabled?
      )
    )
  end

  private

  def update!
    @repository_stock_value.update_data!(repository_stock_value_params, current_user)
  end

  def create!
    repository_cell = @repository_row.repository_cells.create(repository_column: @repository_column)
    @repository_stock_value = RepositoryStockValue.new_with_payload(
      repository_stock_value_params,
      repository_cell: repository_cell,
      created_by: current_user,
      last_modified_by: current_user,
      comment: repository_stock_value_params[:comment].presence
    )
    @repository_stock_value.save!
  end

  def load_vars
    @repository = Repository.find(params[:repository_id])
    @repository_row = @repository.repository_rows.find(params[:id])
    @repository_column = @repository.repository_columns.find_by(data_type: 'RepositoryStockValue')
    @repository_stock_value = @repository_row.repository_stock_value
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_stock?(@repository)
  end

  def repository_stock_value_params
    params.require(:repository_stock_value).permit(:unit_item_id, :amount, :comment, :low_stock_threshold)
  end

  def log_activity(operator, change_amount, unit, new_amount, comment)
    Activities::CreateActivityService
      .call(activity_type: "inventory_item_stock_#{operator}",
            owner: current_user,
            subject: @repository,
            team: @repository.team,
            message_items: {
              repository: @repository.id,
              repository_row: @repository_row.id,
              change_amount: change_amount,
              unit: unit,
              new_amount: new_amount,
              comment: comment
            })
  end
end
