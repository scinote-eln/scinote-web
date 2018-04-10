class RepositoryColumnsController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars, except: %i(create index create_html)
  before_action :load_vars_nested, only: %i(create index create_html)
  before_action :check_create_permissions, only: :create
  before_action :check_manage_permissions, except: %i(create index create_html)
  before_action :load_repository_columns, only: :index

  def index; end

  def create_html
    @repository_column = RepositoryColumn.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'repository_columns/manage_column_modal.html.erb'
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
      if @repository_column.save
        generate_repository_list_items(params[:list_items])
        format.json do
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
        end
      else
        format.json do
          render json: { message: @repository_column.errors.full_messages },
                 status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'repository_columns/manage_column_modal.html.erb'
          )
        }
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        @repository_column.update_attributes(repository_column_params)
        if @repository_column.save
          update_repository_list_items(params[:list_items])
          render json: {
            id: @repository_column.id,
            name: escape_input(@repository_column.name),
            message: t('libraries.repository_columns.update.success_flash',
                       name: @repository_column.name)
          }, status: :ok
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
            partial: 'repository_columns/delete_column_modal_body.html.erb',
            locals: { column_index: params[:column_index] }
          )
        }
      end
    end
  end

  def destroy
    @del_repository_column = @repository_column.dup
    column_id = @repository_column.id
    respond_to do |format|
      format.json do
        if @repository_column.destroy
          RepositoryTableState.update_state(
            @del_repository_column,
            params[:repository_column][:column_index],
            current_user
          )
          render json: {
            message: t('libraries.repository_columns.destroy.success_flash',
                       name: @del_repository_column.name),
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

  private

  def load_vars
    @repository = Repository.find_by_id(params[:repository_id])
    render_404 unless @repository
    @repository_column = RepositoryColumn.find_by_id(params[:id])
    render_404 unless @repository_column
  end

  def load_vars_nested
    @repository = Repository.find_by_id(params[:repository_id])
    render_404 unless @repository
  end

  def load_repository_columns
    @repository_columns = @repository.repository_columns
                                     .order(created_at: :desc)
  end

  def check_create_permissions
    render_403 unless can_create_repository_columns?(@repository.team)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository_column?(@repository_column)
  end

  def repository_column_params
    params.require(:repository_column).permit(:name, :data_type)
  end

  def generate_repository_list_items(item_names)
    return unless @repository_column.data_type == 'RepositoryListValue'
    column_items = @repository_column.repository_list_items.size
    item_names.split(',').uniq.each do |name|
      next if column_items >= Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN
      RepositoryListItem.create(
        repository: @repository,
        repository_column: @repository_column,
        data: name,
        created_by: current_user,
        last_modified_by: current_user
      )
      column_items += 1
    end
  end

  def update_repository_list_items(item_names)
    return unless @repository_column.data_type == 'RepositoryListValue'
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
    items_list.each do |name|
      next if @repository_column.repository_list_items.find_by_data(name)
      next if column_items >= Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN
      RepositoryListItem.create(
        repository: @repository,
        repository_column: @repository_column,
        data: name,
        created_by: current_user,
        last_modified_by: current_user
      )
      column_items += 1
    end
  end
end
