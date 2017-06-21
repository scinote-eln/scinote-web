class RepositoriesController < ApplicationController
  before_action :load_vars,
                except: %i(repository_table_index parse_sheet import_records)
  before_action :check_team, only: %i(parse_sheet import_records)
  before_action :check_view_all_permissions, only: :index
  before_action :check_edit_and_destroy_permissions,
                only: %i(destroy destroy_modal rename_modal update)
  before_action :check_copy_permissions,
                only: %i(copy_modal copy)
  before_action :check_create_permissions,
                only: %i(create_new_modal create)

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

  def parse_sheet
    repository = current_team.repositories.find_by_id(params[:id])
    parsed_file = ImportRepository::ParseRepository.new(
      file: params[:file],
      repository: repository,
      session: session
    )

    respond_to do |format|
      unless params[:file]
        repository_response(t("teams.parse_sheet.errors.no_file_selected"))
        return
      end
      begin
        if parsed_file.too_large?
          repository_response(t('general.file.size_exceeded',
                                file_size: Constants::FILE_MAX_SIZE_MB))
        else
          flash[:notice] = t('teams.parse_sheet.errors.empty_file')
          redirect_to back and return if parsed_file.empty?
          @import_data = parsed_file.data
          if parsed_file.generated_temp_file?
            format.json do
              render json: {
                html: render_to_string(
                  partial: 'repositories/parse_records_modal.html.erb'
                )
              }
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
  end

  def import_records
    import_records = repostiory_import_actions
    status = import_records.import!
    respond_to do |format|
      format.json do
        if status[:status] == :ok
          flash[:success] = t('repositories.import_records.success_flash',
                              number_of_rows: status[:nr_of_added])
          render json: {}, status: :ok
        else
          flash[:alert] = t('repositories.import_records.error_flash',
                             message: status[:errors])
          render json: {}, status: :unprocessable_entity
        end
      end

    end
  end

  private

  def repostiory_import_actions
    ImportRepository::ImportRecords.new(
      temp_file: TempFile.find_by_id(params[:file_id]),
      repository: current_team.repositories.find_by_id(params[:id]),
      mappings: params[:mappings],
      session: session,
      user: current_user
    )
  end

  def load_vars
    @team = Team.find_by_id(params[:team_id])
    render_404 unless @team
    @repositories = @team.repositories.order(created_at: :asc)
  end

  def check_team
    render_404 unless params[:team_id].to_i == current_team.id
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

  def repository_response(message)
    format.html do
      flash[:alert] = message
      redirect_to :back
    end
    format.json do
      render json: { message: message },
        status: :unprocessable_entity
    end
  end
end
