class RepositoryColumnsController < ApplicationController
  include InputSanitizeHelper
  include RepositoryColumnsHelper

  before_action :load_repository
  before_action :load_column, only: %i(edit update destroy_html destroy items)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(edit update destroy_html destroy)
  before_action :load_asset_type_columns, only: :available_asset_type_columns

  def index
    render json: {
      id: @repository.id,
      html: render_to_string(
        partial: 'repository_columns/manage_column_modal_index'
      )
    }
  end

  def new
    @repository_column = RepositoryColumn.new
    render json: {
      html: render_to_string(partial: 'repository_columns/manage_column_modal_content')
    }
  end

  def create
    raise NotImplementedError
  end

  def describe_all
    response_json = @repository.repository_columns
                               .where(data_type: Extends::REPOSITORY_ADVANCED_SEARCHABLE_COLUMNS)
                               .map do |column|
      {
        id: column.id,
        name: escape_input(column.name),
        data_type: column.data_type,
        items: column.items&.map { |item| { value: item.id, label: escape_input(item.data) } }
      }
    end
    render json: { response: response_json }
  end

  def edit
    render json: {
      html: render_to_string(
        partial: 'repository_columns/manage_column_modal_content'
      )
    }
  end

  def update
    raise NotImplementedError
  end

  def destroy_html
    render json: {
      html: render_to_string(partial: 'repository_columns/delete_column_modal_body')
    }
  end

  def destroy
    column_id = @repository_column.id
    column_name = @repository_column.name

    log_activity(:delete_column_inventory) # Should we move this call somewhere?
    if @repository_column.destroy
      render json: {
        message: t('libraries.repository_columns.destroy.success_flash', name: escape_input(column_name)),
        id: column_id
      }
    else
      render json: {
        message: t('libraries.repository_columns.destroy.error_flash'),
        status: :unprocessable_entity
      }
    end
  end

  def items
    raise NotImplementedError
  end

  def available_asset_type_columns
    render json: { data: @asset_columns.map { |c| [c.id, c.name] } }, status: :ok
  end

  def available_columns
    render json: { columns: @repository.repository_columns.pluck(:id) }, status: :ok
  end

  private

  include StringUtility
  AvailableRepositoryColumn = Struct.new(:id, :name)

  def load_repository
    @repository = Repository.accessible_by_teams(current_team).find_by(id: params[:repository_id])
    render_404 unless @repository
  end

  def load_column
    @repository_column = @repository.repository_columns.find_by(id: params[:id])
    render_404 unless @repository_column
  end

  def load_asset_type_columns
    render_403 && return unless can_read_repository?(@repository)

    @asset_columns = load_asset_columns(search_params[:q])
  end

  def check_create_permissions
    render_403 unless can_create_repository_columns?(@repository)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_column?(@repository_column)
  end

  def search_params
    params.permit(:q, :repository_id)
  end

  def load_asset_columns(query)
    @repository.repository_columns
               .asset_type.name_like(query)
               .limit(Constants::SEARCH_LIMIT)
               .select(:id, :name)
               .collect do |column|
                 AvailableRepositoryColumn.new(
                   column.id,
                   ellipsize(column.name, 75, 50)
                 )
               end
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @repository,
            team: @repository.team,
            message_items: {
              repository_column: @repository_column.id,
              repository: @repository.id
            })
  end
end
