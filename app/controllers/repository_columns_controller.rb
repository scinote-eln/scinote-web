class RepositoryColumnsController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars, except: :create
  before_action :load_vars_nested, only: :create
  before_action :check_permissions

  def create
    @repository_column = RepositoryColumn.new(repository_column_params)
    @repository_column.repository = @repository
    @repository_column.created_by = current_user
    @repository_column.data_type = :RepositoryTextValue

    respond_to do |format|
      if @repository_column.save
        format.json do
          render json: {
            id: @repository_column.id,
            name: escape_input(@repository_column.name),
            edit_url:
              edit_repository_repository_column_path(@repository,
                                                     @repository_column),
            update_url:
              repository_repository_column_path(@repository,
                                                @repository_column),
            destroy_html_url:
              repository_columns_destroy_html_path(
                @repository, @repository_column
              )
          },
          status: :ok
        end
      else
        format.json do
          render json: @repository_column.errors.to_json,
                 status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.json do
        render json: { status: :ok }
      end
    end
  end

  def update
    respond_to do |format|
      format.json do
        @repository_column.update_attributes(repository_column_params)
        if @repository_column.save
          render json: { status: :ok }
        else
          render json: @repository_column.errors.to_json,
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
            partial: 'repositories/delete_column_modal_body.html.erb',
            locals: { column_index: params[:column_index] }
          )
        }
      end
    end
  end

  def destroy
    @del_repository_column = @repository_column.dup
    respond_to do |format|
      format.json do
        if @repository_column.destroy
          RepositoryTableState.update_state(
            @del_repository_column,
            params[:repository_column][:column_index],
            current_user
          )
          render json: { status: :ok }
        else
          render json: { status: :unprocessable_entity }
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

  def check_permissions
    render_403 unless can_manage_repository_column?(@repository.team)
  end

  def repository_column_params
    params.require(:repository_column).permit(:name)
  end
end
