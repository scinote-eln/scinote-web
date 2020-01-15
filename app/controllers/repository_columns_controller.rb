class RepositoryColumnsController < ApplicationController
  include InputSanitizeHelper
  include RepositoryColumnsHelper

  ACTIONS = %i(
    create index_html create_html available_asset_type_columns available_columns
  ).freeze
  before_action :load_vars,
                except: ACTIONS
  before_action :load_vars_nested,
                only: ACTIONS
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions,
                except: ACTIONS
  before_action :load_asset_type_columns, only: :available_asset_type_columns

  def index_html
    render json: {
      id: @repository.id,
      html: render_to_string(
        partial: 'repository_columns/manage_column_modal_index.html.erb'
      )
    }
  end

  def create_html
    @repository_column = RepositoryColumn.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'repository_columns/manage_column_modal_content.html.erb'
          )
        }
      end
    end
  end

  def create
    @repository_column = RepositoryColumn.new(repository_column_params)
    @repository_column.repository = @repository
    @repository_column.created_by = current_user

    respond_to do |format|
      format.json do
        if @repository_column.save
          log_activity(:create_column_inventory)

          if generate_repository_list_items(params[:list_items])
            render json: {
              id: @repository_column.id,
              name: escape_input(@repository_column.name),
              message: t('libraries.repository_columns.create.success_flash',
                         name: @repository_column.name),
              edit_url:
                edit_repository_repository_column_path(@repository,
                                                       @repository_column),
              update_url:
                repository_repository_column_path(@repository,
                                                  @repository_column),
              destroy_html_url:
                repository_columns_destroy_html_path(@repository,
                                                     @repository_column)
            },
            status: :ok
          else
            render json: {
              message: {
                repository_list_items:
                  t('libraries.repository_columns.repository_list_items_limit',
                    limit: Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN)
              }
            }, status: :unprocessable_entity
          end
        else
          render json: { message: @repository_column.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    render json: { html: render_to_string(partial: 'repository_columns/manage_column_modal_content.html.erb') }
  end

  def update
    respond_to do |format|
      format.json do
        @repository_column.update(repository_column_params)
        if @repository_column.save
          log_activity(:edit_column_inventory)

          if update_repository_list_items(params[:list_items])
            render json: {
              id: @repository_column.id,
              name: escape_input(@repository_column.name),
              message: t('libraries.repository_columns.update.success_flash',
                         name: escape_input(@repository_column.name))
            }, status: :ok
          else
            render json: {
              message: {
                repository_list_items:
                  t('libraries.repository_columns.repository_list_items_limit',
                    limit: Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN)
              }
            }, status: :unprocessable_entity
          end
        else
          render json: { message: @repository_column.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end

  def destroy_html
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'repository_columns/delete_column_modal_body.html.erb'
          )
        }
      end
    end
  end

  def destroy
    column_id = @repository_column.id
    column_name = @repository_column.name

    log_activity(:delete_column_inventory) # Should we move this call somewhere?
    respond_to do |format|
      format.json do
        if @repository_column.destroy
          render json: {
            message: t('libraries.repository_columns.destroy.success_flash',
                       name: escape_input(column_name)),
            id: column_id,
            status: :ok
          }
        else
          render json: {
            message: t('libraries.repository_columns.destroy.error_flash'),
            status: :unprocessable_entity
          }
        end
      end
    end
  end

  def available_asset_type_columns
    if @asset_columns.empty?
      render json: {
        no_items: t(
          'projects.reports.new.save_PDF_to_inventory_modal.no_columns'
        )
        }, status: :ok
    else
      render json: { results: @asset_columns }, status: :ok
    end
  end

  def available_columns
    render json: { columns: @repository.available_columns_ids }, status: :ok
  end

  private

  include StringUtility
  AvailableRepositoryColumn = Struct.new(:id, :name)

  def load_vars
    @repository = Repository.accessible_by_teams(current_team).find_by_id(params[:repository_id])
    render_404 unless @repository
    @repository_column = @repository.repository_columns.find_by_id(params[:id])
    render_404 unless @repository_column
  end

  def load_vars_nested
    @repository = Repository.accessible_by_teams(current_team).find_by_id(params[:repository_id])
    render_404 unless @repository
  end

  def load_asset_type_columns
    render_403 unless can_read_repository?(@repository)
    @asset_columns = load_asset_columns(search_params[:q])
  end

  def check_create_permissions
    render_403 unless can_create_repository_columns?(@repository)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_column?(@repository_column)
  end

  def repository_column_params
    params.require(:repository_column).permit(:name, :data_type)
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

  def generate_repository_list_items(item_names)
    return true unless @repository_column.data_type == 'RepositoryListValue'
    column_items = @repository_column.repository_list_items.size
    success = true
    item_names.split(',').uniq.each do |name|
      if column_items >= Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN
        success = false
        next
      end
      RepositoryListItem.create(
        repository: @repository,
        repository_column: @repository_column,
        data: name,
        created_by: current_user,
        last_modified_by: current_user
      )
      column_items += 1
    end
    success
  end

  def update_repository_list_items(item_names)
    return true unless @repository_column.data_type == 'RepositoryListValue'
    column_items = @repository_column.repository_list_items.size
    items_list = item_names.split(',').uniq
    existing = @repository_column.repository_list_items.pluck(:data)
    existing.each do |name|
      next if items_list.include? name
      list_item_id = @repository_column.repository_list_items
                                       .find_by_data(name)
                                       .destroy
                                       .id
      RepositoryCell.where(
        'value_type = ? AND value_id = ?',
        'RepositoryListValue',
        list_item_id
      ).destroy_all
    end
    success = true
    items_list.each do |name|
      next if @repository_column.repository_list_items.find_by_data(name)
      if column_items >= Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN
        success = false
        next
      end
      RepositoryListItem.create(
        repository: @repository,
        repository_column: @repository_column,
        data: name,
        created_by: current_user,
        last_modified_by: current_user
      )
      column_items += 1
    end
    success
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @repository,
            team: current_team,
            message_items: {
              repository_column: @repository_column.id,
              repository: @repository.id
            })
  end
end
