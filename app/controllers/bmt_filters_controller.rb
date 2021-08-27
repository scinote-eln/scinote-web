# frozen_string_literal: true

class BmtFiltersController < ApplicationController
  before_action :check_manage_permission, except: :index

  def index
    render json: BmtFilter.all, each_serializer: BmtFilterSerializer
  end

  def create
    filter = BmtFilter.new(
      name: filters_params[:name],
      filters: JSON.parse(filters_params[:filters])
    )
    filter.created_by = current_user
    if filter.save
      render json: filter, serializer: BmtFilterSerializer
    else
      render json: filter.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy
    filter = BmtFilter.find(params[:id])
    render json: { status: filter.destroy }
  end

  private

  def filters_params
    params.require(:bmt_filter).permit(:name, :filters)
  end

  def check_manage_permission
    render_403 && return unless can_manage_bmt_filters?(@current_team)
  end
end
