class RepositoriesController < ApplicationController
  before_action :load_vars,
                except: %i(index create create_modal parse_sheet import_records)
  before_action :load_parent_vars, except:
    %i(repository_table_index export_repository parse_sheet import_records)
  before_action :check_team, only: %i(parse_sheet import_records)
  before_action :check_view_all_permissions, only: :index
  before_action :check_view_permissions, only: %i(export_repository show)
  before_action :check_manage_permissions, only:
    %i(destroy destroy_modal rename_modal update)
  before_action :check_create_permissions, only:
    %i(create_modal create copy_modal copy)

  layout 'fluid'

  def index
    unless @repositories.length.zero? && current_team
      redirect_to repository_path(@repositories.first) and return
    end
    render 'repositories/index'
  end

  def show
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
          render json: { url: repository_path(@repository) },
            status: :ok
        else
          render json: @repository.errors,
            status: :unprocessable_entity
        end
      end
    end
  end

  def destroy_modal
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
    flash[:success] = t('repositories.index.delete_flash',
                        name: @repository.name)
    @repository.discard
    @repository.destroy_discarded(current_user.id)
    redirect_to team_repositories_path
  end

  def rename_modal
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
    if @repository.nil? || !can_read_team?(@repository.team)
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

  def parse_sheet
    repository = current_team.repositories.find_by_id(import_params[:id])

    unless import_params[:file]
      repository_response(t('teams.parse_sheet.errors.no_file_selected'))
      return
    end
    begin
      parsed_file = ImportRepository::ParseRepository.new(
        file: import_params[:file],
        repository: repository,
        session: session
      )
      if parsed_file.too_large?
        repository_response(t('general.file.size_exceeded',
                              file_size: Rails.configuration.x.file_max_size_mb))
      elsif parsed_file.has_too_many_rows?
        repository_response(
          t('repositories.import_records.error_message.items_limit',
            items_size: Constants::IMPORT_REPOSITORY_ITEMS_LIMIT)
        )
      else
        @import_data = parsed_file.data

        if @import_data.header.empty? || @import_data.columns.empty?
          return repository_response(t('teams.parse_sheet.errors.empty_file'))
        end

        if (@temp_file = parsed_file.generate_temp_file)
          respond_to do |format|
            format.json do
              render json: {
                html: render_to_string(
                  partial: 'repositories/parse_records_modal.html.erb'
                )
              }
            end
          end
        else
          repository_response(t('teams.parse_sheet.errors.temp_file_failure'))
        end
      end
    rescue ArgumentError, CSV::MalformedCSVError
      repository_response(t('teams.parse_sheet.errors.invalid_file',
                            encoding: ''.encoding))
    rescue TypeError
      repository_response(t('teams.parse_sheet.errors.invalid_extension'))
    end
  end

  def import_records
    respond_to do |format|
      format.json do
        # Check if there exist mapping for repository record (it's mandatory)
        if import_params[:mappings].value?('-1')
          import_records = repostiory_import_actions
          status = import_records.import!

          if status[:status] == :ok
            flash[:success] = t('repositories.import_records.success_flash',
                                number_of_rows: status[:nr_of_added],
                                total_nr: status[:total_nr])
            render json: {}, status: :ok
          else
            flash[:alert] =
              t('repositories.import_records.partial_success_flash',
                nr: status[:nr_of_added], total_nr: status[:total_nr])
            render json: {}, status: :unprocessable_entity
          end
        else
          render json: {
            html: render_to_string(
              partial: 'shared/flash_errors.html.erb',
              locals: { error_title: t('repositories.import_records'\
                                       '.error_message.errors_list_title'),
                        error: t('repositories.import_records.error_message'\
                                 '.no_repository_name') }
            )
          },
          status: :unprocessable_entity
        end
      end
    end
  end

  def export_repository
    if params[:row_ids] && params[:header_ids]
      RepositoryZipExport.generate_zip(params, @repository, current_user)
    else
      flash[:alert] = t('zip_export.export_error')
    end
    redirect_back(fallback_location: root_path)
  end

  private

  def repostiory_import_actions
    ImportRepository::ImportRecords.new(
      temp_file: TempFile.find_by_id(import_params[:file_id]),
      repository: current_team.repositories.find_by_id(import_params[:id]),
      mappings: import_params[:mappings],
      session: session,
      user: current_user
    )
  end

  def load_vars
    repository_id = params[:id] || params[:repository_id]
    @repository = Repository.find_by_id(repository_id)
    render_404 unless @repository
  end

  def load_parent_vars
    @team = current_team
    render_404 unless @team
    @repositories = @team.repositories.order(created_at: :asc)
  end

  def check_team
    render_404 unless params[:team_id].to_i == current_team.id
  end

  def check_view_all_permissions
    render_403 unless can_read_team?(@team)
  end

  def check_view_permissions
    render_403 unless can_read_team?(@repository.team)
  end

  def check_create_permissions
    unless can_create_repositories?(@team) ||
           @team.repositories.count < Rails.configuration.x.repositories_limit
      render_403
    end
  end

  def check_manage_permissions
    render_403 unless can_manage_repository?(@repository)
  end

  def repository_params
    params.require(:repository).permit(:name)
  end

  def import_params
    params.permit(:id, :file, :file_id, mappings: {}).to_h
  end

  def repository_response(message)
    respond_to do |format|
      format.html do
        flash[:alert] = message
        redirect_back(fallback_location: root_path)
      end
      format.json do
        render json: { message: message },
          status: :unprocessable_entity
      end
    end
  end
end
