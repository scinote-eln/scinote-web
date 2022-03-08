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
    @repository_table_filter = @repository.repository_table_filters.new(
      name: repository_table_filter_params[:name],
      default_columns: repository_table_filter_elements_params[:default_columns],
      created_by: current_user
    )
    @repository_table_filter.transaction do
      repository_table_filter_elements_params[:custom_columns].each do |custom_column_params|
        @repository_table_filter.repository_table_filter_elements.build(custom_column_params)
      end
      @repository_table_filter.save!
    end

    render json: @repository_table_filter, serializer: RepositoryFilterSerializer
  rescue ActiveRecord::RecordInvalid
    render_errors
  end

  def update
    @repository_table_filter.transaction do
      @repository_table_filter.name = repository_table_filter_params[:name]
      @repository_table_filter.default_columns = repository_table_filter_elements_params[:default_columns]

      repository_column_ids =
        repository_table_filter_elements_params[:custom_columns].map { |r| r['repository_column_id'] }
      @repository_table_filter.repository_table_filter_elements
                              .where.not(
                                repository_column_id: repository_column_ids
                              ).find_each(&:destroy!)

      repository_table_filter_elements_params[:custom_columns].each do |custom_column_params|
        @repository_table_filter.repository_table_filter_elements
                                .find_or_initialize_by(
                                  repository_column_id: custom_column_params['repository_column_id']
                                ).update!(custom_column_params)
      end

      @repository_table_filter.save!
    end

    render json: @repository_table_filter, serializer: RepositoryFilterSerializer
  rescue ActiveRecord::RecordInvalid
    render_errors
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

  def render_errors
    message = if @repository_table_filter.errors[:repository_table_filter_elements]
                I18n.t('activerecord.errors.models.repository_table_filter_element.attributes.parameters.must_be_valid')
              elsif @repository_table_filter.errors[:repository_column].present?
                I18n.t('activerecord.errors.models.repository_table_filter_element.attributes.repository_column.must_exist')
              else
                I18n.t('activerecord.errors.models.repository_table_filter_element.general')
              end
    render json: { message: message }, status: :unprocessable_entity
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
