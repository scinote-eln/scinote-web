# frozen_string_literal: true

class RepositoryTableFiltersController < ApplicationController
  include InputSanitizeHelper

  before_action :load_repository
  before_action :load_repository_table_filter, only: %i(show update destroy)
  before_action :check_read_permissions, except: %i(create update destroy)
  before_action :check_create_permissions, only: %i(create)
  before_action :check_manage_permissions, only: %i(update destroy)

  def index
    render json: @repository.repository_table_filters
  end

  def show
    render json: @repository_table_filter, include: :repository_table_filter_elements
  end

  def create
    repository_table_filter = @repository.repository_table_filters.new(
      default_columns: repository_table_filter_params[:default_columns],
      created_by: current_user
    )
    repository_table_filter.transaction do
      repository_table_filter.save!
      repository_table_filter_params[:custom_columns].each do |custom_column_params|
        repository_table_filter.repository_table_filter_elements.create!(custom_column_params)
      end
    end
    if repository_table_filter.persisted?
      render json: repository_table_filter
    else
      render json: repository_table_filter.errors, status: :unprocessable_entity
    end
  end

  def update
    @repository_table_filter.transaction do
      @repository_table_filter.default_columns = repository_table_filter_params[:default_columns]
      repository_table_filter_params[:custom_columns].each do |custom_column_params|
        @repository_table_filter.repository_table_filter_elements
                                .find_by(repository_column_id: custom_column_params[:repository_column_id])
                                .update!(custom_column_params)
      end
    end
    if @repository_table_filter.persisted?
      render json: @repository_table_filter
    else
      render json: repository_table_filter.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @repository_table_filter.destroy!
    render body: nil, status: :ok
  end

  private

  def load_repository
    @repository = Repository.accessible_by_teams(current_team).find_by(id: params[:repository_id])
    render_403 unless can_read_repository?(@repository)
  end

  def load_repository_table_filter
    @repository_table_filter = @repository.repository_table_filters.find(params[:id])
  end

  def check_read_permissions
    render_403 unless can_read_repository?(@repository)
  end

  def check_create_permissions
    render_403 unless can_manage_repository?(@repository)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository?(@repository)
  end

  def repository_table_filter_params
    require(:repository_table_filter).permit(:name, default_columns: [], custom_columns: [])
  end
end
