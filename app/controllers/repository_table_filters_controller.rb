# frozen_string_literal: true

class RepositoryTableFiltersController < ApplicationController
  include InputSanitizeHelper

  before_action :load_repository
  before_action :load_repository_table_filter, only: %i(show update destroy)
  before_action :check_read_permissions, except: %i(create update destroy)
  before_action :check_create_permissions, only: %i(create)
  before_action :check_manage_permissions, only: %i(update destroy)

  def index
    render json: @repository.repository_table_filters.order(:name), each_serializer: RepositoryFilterSerializer
  end

  def show
    render json: @repository_table_filter, include: :repository_table_filter_elements
  end

  def create
    repository_table_filter = @repository.repository_table_filters.new(
      name: repository_table_filter_params[:name],
      default_columns: repository_table_filter_elements_params[:default_columns],
      created_by: current_user
    )
    repository_table_filter.transaction do
      repository_table_filter.save!
      repository_table_filter_elements_params[:custom_columns].each do |custom_column_params|
        repository_table_filter.repository_table_filter_elements.create!(custom_column_params)
      end
    end

    render json: repository_table_filter, serializer: RepositoryFilterSerializer
  rescue ActiveRecord::RecordInvalid
    error_key =
      repository_table_filter.errors[:repository_table_filter_elements] ? 'repository_column.must_exist' : 'general'
    message = I18n.t("activerecord.errors.models.repository_table_filter_element.attributes.#{error_key}")
    render json: { message: message }, status: :unprocessable_entity
  end

  def update
    @repository_table_filter.transaction do
      @repository_table_filter.name = repository_table_filter_params[:name]
      @repository_table_filter.default_columns = repository_table_filter_elements_params[:default_columns]
      @repository_table_filter.save!

      repository_column_ids =
        repository_table_filter_elements_params[:custom_columns].map { |r| r['repository_column_id'] }
      @repository_table_filter.repository_table_filter_elements
                              .where.not(
                                repository_column_id: repository_column_ids
                              ).find_each(&:destroy!)

      repository_table_filter_elements_params[:custom_columns].each do |custom_column_params|
        @repository_table_filter.repository_table_filter_elements
                                .find_or_initialize_by(repository_column_id: custom_column_params['repository_column_id'])
                                .update!(custom_column_params)
      end
    end

    render json: @repository_table_filter, serializer: RepositoryFilterSerializer
  rescue ActiveRecord::RecordInvalid
    error_key =
      @repository_table_filter.errors[:repository_table_filter_elements] ? 'repository_column.must_exist' : 'general'
    message = I18n.t("activerecord.errors.models.repository_table_filter_element.attributes.#{error_key}")
    render json: { message: message }, status: :unprocessable_entity
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
    render_403 unless can_manage_repository_filters?(@repository)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_filters?(@repository)
  end

  def repository_table_filter_elements_params
    columns = JSON.parse(repository_table_filter_params[:repository_table_filter_elements_json])

    @repository_table_filter_elements_params ||= {
      default_columns: columns.select { |column_params| column_params['repository_column_id'].is_a?(String) },
      custom_columns: columns.select { |column_params| column_params['repository_column_id'].is_a?(Integer) }
    }
  end

  def repository_table_filter_params
    params.require(:repository_table_filter).permit(:name, :repository_table_filter_elements_json)
  end
end
