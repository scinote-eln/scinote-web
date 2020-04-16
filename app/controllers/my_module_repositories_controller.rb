# frozen_string_literal: true

class MyModuleRepositoriesController < ApplicationController
  before_action :load_my_module, only: %i(show full_view_table dropdown_list)
  before_action :load_repository, only: %i(show full_view_table)
  before_action :check_my_module_view_permissions, only: %i(show full_view_table dropdown_list)
  before_action :check_repository_view_permissions, only: %i(show full_view_table)

  def show
    @draw = params[:draw].to_i
    per_page = params[:length] == '-1' ? 10 : params[:length].to_i
    page = (params[:start].to_i / per_page) + 1
    datatable_service = RepositoryDatatableService.new(@repository, params, current_user, @my_module)

    @datatable_params = {
      view_mode: params[:view_mode],
      skip_custom_columns: params[:skip_custom_columns]
    }
    @all_rows_count = datatable_service.all_count
    @columns_mappings = datatable_service.mappings
    @repository_rows = datatable_service.repository_rows
                                        .preload(:repository_columns,
                                                 :created_by,
                                                 repository_cells: @repository.cell_preload_includes)
                                        .page(page)
                                        .per(per_page)

    render 'repository_rows/index.json'
  end

  def full_view_table
    render json: { html: render_to_string(partial: 'my_modules/repositories/full_view_table') }
  end

  def dropdown_list
    @repositories = Repository.accessible_by_teams(current_team)

    render json: { html: render_to_string(partial: 'my_modules/repositories/repositories_dropdown_list') }
  end

  private

  def load_my_module
    @my_module = MyModule.find_by(id: params[:my_module_id])
    render_404 unless @my_module
  end

  def load_repository
    @repository = Repository.find_by(id: params[:id])
    render_404 unless @repository
  end

  def check_my_module_view_permissions
    render_403 unless can_read_experiment?(@my_module.experiment)
  end

  def check_repository_view_permissions
    render_403 unless can_read_repository?(@repository)
  end
end
