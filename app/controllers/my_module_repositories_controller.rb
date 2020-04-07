# frozen_string_literal: true

class MyModuleRepositoriesController < ApplicationController
  before_action :load_vars
  before_action :check_view_permissions

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
    @repository_rows = datatable_service.repository_rows
                                        .preload(:repository_columns,
                                                 :created_by,
                                                 repository_cells: @repository.cell_preload_includes)
                                        .page(page)
                                        .per(per_page)

    render 'repository_rows/index.json'
  end

  private

  def load_vars
    @my_module = MyModule.find(params[:my_module_id])
    @repository = Repository.find(params[:id])

    render_404 unless @my_module && @repository
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@my_module.experiment) &&
                      can_read_repository?(@repository)
  end
end
