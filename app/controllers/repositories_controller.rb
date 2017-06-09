class RepositoriesController < ApplicationController
  before_action :load_vars, except: %i(repository_table_index export_repository)
  before_action :check_view_all_permissions, only: :index
  before_action :check_edit_and_destroy_permissions, only:
    %(destroy destroy_modal rename_modal update)
  before_action :check_copy_permissions, only:
    %(copy_modal copy)
  before_action :check_create_permissions, only:
    %(create_new_modal create)

  def index
    render('repositories/index')
  end

  def show_tab
    @repository = Repository.find_by_id(params[:repository_id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'repositories/repository.html.erb',
            locals: { repository: @repository }
          )
        }
      end
    end
  end

  def create_modal
    @repository = Repository.new
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'create_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def create
    @repository = Repository.new(
      team: @team,
      created_by: current_user
    )
    @repository.assign_attributes(repository_params)

    respond_to do |format|
      format.json do
        if @repository.save
          flash[:success] = t('repositories.index.modal_create.success_flash',
                              name: @repository.name)
          render json: { url: team_repositories_path(repository: @repository) },
            status: :ok
        else
          render json: @repository.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def destroy_modal
    @repository = Repository.find(params[:repository_id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'delete_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def destroy
    @repository = Repository.find(params[:id])
    flash[:success] = t('repositories.index.delete_flash',
                        name: @repository.name)
    @repository.destroy
    redirect_to team_repositories_path
  end

  def rename_modal
    @repository = Repository.find(params[:repository_id])
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'rename_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def update
    @repository = Repository.find(params[:id])
    old_name = @repository.name
    @repository.update_attributes(repository_params)

    respond_to do |format|
      format.json do
        if @repository.save
          flash[:success] = t('repositories.index.rename_flash',
                              old_name: old_name, new_name: @repository.name)
          render json: {
            url: team_repositories_path(repository: @repository)
          }, status: :ok
        else
          render json: @repository.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def copy_modal
    @repository = Repository.find(params[:repository_id])
    @tmp_repository = Repository.new(
      team: @team,
      created_by: current_user,
      name: @repository.name
    )
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'copy_repository_modal.html.erb'
          )
        }
      end
    end
  end

  def copy
    @repository = Repository.find(params[:repository_id])
    @tmp_repository = Repository.new(
      team: @team,
      created_by: current_user
    )
    @tmp_repository.assign_attributes(repository_params)

    respond_to do |format|
      format.json do
        if !@tmp_repository.valid?
          render json: @tmp_repository.errors, status: :unprocessable_entity
        else
          copied_repository =
            @repository.copy(current_user, @tmp_repository.name)

          if !copied_repository
            render json: { 'name': ['Server error'] },
            status: :unprocessable_entity
          else
            flash[:success] = t(
              'repositories.index.copy_flash',
              old: @repository.name,
              new: copied_repository.name
            )
            render json: {
              url: team_repositories_path(repository: copied_repository)
            }, status: :ok
          end
        end
      end
    end
  end

  # AJAX actions
  def repository_table_index
    @repository = Repository.find_by_id(params[:repository_id])
    if @repository.nil? || !can_view_repository(@repository)
      render_403
    else
      respond_to do |format|
        format.html
        format.json do
          render json: ::RepositoryDatatable.new(view_context,
                                                 @repository,
                                                 nil,
                                                 current_user)
        end
      end
    end
  end

  def export_repository
    if params[:row_ids] && params[:header_ids]
      generate_zip
    else
      flash[:alert] = t('zip_export.export_error')
    end
    redirect_to :back
  end

  private

  def load_vars
    @team = Team.find_by_id(params[:team_id])
    render_404 unless @team
    @repositories = @team.repositories.order(created_at: :asc)
  end

  def check_view_all_permissions
    render_403 unless can_view_team_repositories(@team)
  end

  def check_create_permissions
    render_403 unless can_create_repository(@team)
  end

  def check_edit_and_destroy_permissions
    render_403 unless can_edit_and_destroy_repository(@repository)
  end

  def check_copy_permissions
    render_403 unless can_copy_repository(@repository)
  end

  def repository_params
    params.require(:repository).permit(:name)
  end

  def generate_zip
    zip = ZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
      to_csv(RepositoryRow.where(id: params[:row_ids]), params[:header_ids]),
      :repositories
    )
  end

  def to_csv(rows, header_ids)
    require 'csv'

    # Parse header IDs (magic numbers should be refactored - see
    # sample-datatable.js)
    header_names = []
    header_ids.each do |header|
      if header == '-1'
        next
      elsif header == '-2'
        header_names << I18n.t('repositories.table.row_name')
      elsif header == '-3'
        header_names << I18n.t('repositories.table.added_by')
      elsif header == '-4'
        header_names << I18n.t('repositories.table.added_on')
      else
        rc = RepositoryColumn.find_by_id(header)
        if rc
          header_names << rc.name
        else
          header_names << nil
        end
      end
    end

    CSV.generate do |csv|
      csv << header_names
      rows.each do |row|
        csv_row = []
        header_ids.each do |header_id|
          if header_id == '-1'
            next
          elsif header_id == '-2'
            csv_row << row.name
          elsif header_id == '-3'
            csv_row << row.created_by.full_name
          elsif header_id == '-4'
            csv_row << I18n.l(row.created_at, format: :full)
          else
            column = row.repository_cells
                        .find_by(repository_column_id: header_id)
            csv_row << (column ? column.value.data : nil)
          end
        end
        csv << csv_row
      end
    end
  end
end
