# frozen_string_literal: true

class RepositoriesController < ApplicationController
  include InventoriesHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include IconsHelper
  include TeamsHelper
  include RepositoriesDatatableHelper

  before_action :switch_team_with_param, only: :show
  before_action :load_repository, except: %i(index create create_modal sidebar archive restore)
  before_action :load_repositories, only: %i(index show sidebar)
  before_action :load_repositories_for_archiving, only: :archive
  before_action :load_repositories_for_restoring, only: :restore
  before_action :check_view_all_permissions, only: %i(index sidebar)
  before_action :check_view_permissions, except: %i(index create_modal create update destroy parse_sheet import_records sidebar archive restore)
  before_action :check_manage_permissions, only: %i(destroy destroy_modal rename_modal update)
  before_action :check_archive_permissions, only: %i(archive restore)
  before_action :check_share_permissions, only: :share_modal
  before_action :check_create_permissions, only: %i(create_modal create)
  before_action :check_copy_permissions, only: %i(copy_modal copy)
  before_action :set_inline_name_editing, only: %i(show)

  layout 'fluid'

  def index
    respond_to do |format|
      format.html do; end
      format.json do
        render json: prepare_repositories_datatable(@repositories, current_team, params)
      end
    end
  end

  def sidebar
    render json: {
      html: render_to_string(partial: 'repositories/sidebar_list.html.erb', locals: {
                               repositories: @repositories,
                               archived: params[:archived] == 'true'
                             })
    }
  end

  def show
    @display_edit_button = can_create_repository_rows?(@repository)
    @display_delete_button = can_delete_repository_rows?(@repository)
    @display_duplicate_button = can_create_repository_rows?(@repository)
    @snapshot_provisioning = @repository.repository_snapshots.provisioning.any?
  end

  def table_toolbar
    render json: {
      html: render_to_string(partial: 'repositories/toolbar_buttons.html.erb')
    }
  end

  def status
    render json: {
      editable: can_manage_repository_rows?(@repository),
      snapshot_provisioning: @repository.repository_snapshots.provisioning.any?
    }
  end

  def load_table
    render json: {
      html: render_to_string(partial: 'repositories/repository_table.html.erb',
                             locals: {
                               repository: @repository,
                               repository_index_link: repository_table_index_path(@repository)
                             })
    }
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

  def share_modal
    respond_to do |format|
      format.json do
        render json: { html: render_to_string(partial: 'share_repository_modal.html.erb') }
      end
    end
  end

  def create
    @repository = Repository.new(
      team: current_team,
      created_by: current_user
    )
    @repository.assign_attributes(repository_params)

    respond_to do |format|
      format.json do
        if @repository.save
          log_activity(:create_inventory)

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

  def archive
    service = Repositories::ArchiveRepositoryService.call(repositories: @repositories,
                                                          user: current_user,
                                                          team: current_team)
    if service.succeed?
      render json: { flash: t('repositories.archive_inventories.success_flash') }, status: :ok
    else
      render json: { error: service.error_message }, status: :unprocessable_entity
    end
  end

  def restore
    service = Repositories::RestoreRepositoryService.call(repositories: @repositories,
                                                          user: current_user,
                                                          team: current_team)
    if service.succeed?
      render json: { flash: t('repositories.restore_inventories.success_flash') }, status: :ok
    else
      render json: { error: service.error_message }, status: :unprocessable_entity
    end
  end

  def destroy
    flash[:success] = t('repositories.index.delete_flash',
                        name: @repository.name)

    log_activity(:delete_inventory) # Log before delete id

    @repository.discard
    @repository.destroy_discarded(current_user.id)
    redirect_to team_repositories_path(archived: true)
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
    @repository.update(repository_params)

    respond_to do |format|
      format.json do
        if @repository.save
          log_activity(:rename_inventory) # Acton only for renaming

          render json: {
            url: team_repositories_path
          }, status: :ok
        else
          render json: @repository.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def copy_modal
    @tmp_repository = Repository.new(
      team: current_team,
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
      team: current_team,
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
              url: repository_path(copied_repository)
            }, status: :ok
          end
        end
      end
    end
  end

  # AJAX actions
  def repository_table_index
    respond_to do |format|
      format.json do
        render json: ::RepositoryDatatable.new(view_context, @repository, nil, current_user)
      end
    end
  end

  def parse_sheet
    render_403 unless can_create_repository_rows?(@repository)

    unless import_params[:file]
      repository_response(t('repositories.parse_sheet.errors.no_file_selected'))
      return
    end
    begin
      parsed_file = ImportRepository::ParseRepository.new(
        file: import_params[:file],
        repository: @repository,
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
          return repository_response(t('repositories.parse_sheet.errors.empty_file'))
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
          repository_response(t('repositories.parse_sheet.errors.temp_file_failure'))
        end
      end
    rescue ArgumentError, CSV::MalformedCSVError
      repository_response(t('repositories.parse_sheet.errors.invalid_file',
                            encoding: ''.encoding))
    rescue TypeError
      repository_response(t('repositories.parse_sheet.errors.invalid_extension'))
    end
  end

  def import_records
    render_403 unless can_create_repository_rows?(Repository.accessible_by_teams(current_team)
                                                            .find_by_id(import_params[:id]))

    respond_to do |format|
      format.json do
        # Check if there exist mapping for repository record (it's mandatory)
        if import_params[:mappings].value?('-1')
          import_records = repostiory_import_actions
          status = import_records.import!

          if status[:status] == :ok
            log_activity(:import_inventory_items,
                         num_of_items: status[:nr_of_added])

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
    respond_to do |format|
      format.json do
        if params[:row_ids] && params[:header_ids]
          RepositoryZipExport.generate_zip(params, @repository, current_user)
          log_activity(:export_inventory_items)
          render json: { message: t('zip_export.export_request_success') }, status: :ok
        else
          render json: { message: t('zip_export.export_error') }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def repostiory_import_actions
    ImportRepository::ImportRecords.new(
      temp_file: TempFile.find_by_id(import_params[:file_id]),
      repository: Repository.accessible_by_teams(current_team).find_by_id(import_params[:id]),
      mappings: import_params[:mappings],
      session: session,
      user: current_user
    )
  end

  def load_repository
    repository_id = params[:id] || params[:repository_id]
    @repository = Repository.accessible_by_teams(current_team).find_by(id: repository_id)
    render_404 unless @repository
  end

  def load_repositories
    @repositories = Repository.accessible_by_teams(current_team).order('repositories.created_at ASC')
    @repositories = if params[:archived] == 'true' || @repository&.archived?
                      @repositories.archived
                    else
                      @repositories.active
                    end
  end

  def load_repositories_for_archiving
    @repositories = current_team.repositories.active.where(id: params[:repository_ids])
  end

  def load_repositories_for_restoring
    @repositories = current_team.repositories.archived.where(id: params[:repository_ids])
  end

  def set_inline_name_editing
    return unless can_manage_repository?(@repository)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'repository',
      item_id: @repository.id,
      field_to_udpate: 'name',
      path_to_update: team_repository_path(@repository),
      label_after: "<span class=\"repository-share-icon\">#{inventory_shared_status_icon(@repository, current_team)}</span>"
    }
  end

  def check_view_all_permissions
    render_403 unless can_read_team?(current_team)
  end

  def check_view_permissions
    render_403 unless can_read_repository?(@repository)
  end

  def check_create_permissions
    render_403 unless can_create_repositories?(current_team)
  end

  def check_copy_permissions
    render_403 if !can_create_repositories?(current_team) || @repository.shared_with?(current_team)
  end

  def check_manage_permissions
    render_403 unless can_manage_repository?(@repository)
  end

  def check_archive_permissions
    @repositories.each do |repository|
      return render_403 unless can_archive_repository?(repository)
    end
  end

  def check_share_permissions
    render_403 if !can_share_repository?(@repository) || current_user.teams.count <= 1
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

  def log_activity(type_of, message_items = {})
    message_items = { repository: @repository.id }.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @repository,
            team: current_team,
            message_items: message_items)
  end
end
