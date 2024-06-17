# frozen_string_literal: true

class RepositoriesController < ApplicationController
  include InventoriesHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  include IconsHelper
  include TeamsHelper
  include RepositoriesDatatableHelper
  include MyModulesHelper

  before_action :load_repository, except: %i(index create create_modal sidebar archive restore actions_toolbar
                                             export_modal export_repositories)
  before_action :load_repositories, only: :index
  before_action :load_repositories_for_archiving, only: :archive
  before_action :load_repositories_for_restoring, only: :restore
  before_action :check_view_all_permissions, only: %i(index sidebar)
  before_action :check_view_permissions, except: %i(index create_modal create update destroy parse_sheet
                                                    import_records sidebar archive restore actions_toolbar
                                                    export_modal export_repositories)
  before_action :check_manage_permissions, only: %i(rename_modal update)
  before_action :check_delete_permissions, only: %i(destroy destroy_modal)
  before_action :check_archive_permissions, only: %i(archive restore)
  before_action :check_share_permissions, only: :share_modal
  before_action :check_create_permissions, only: %i(create_modal create)
  before_action :check_copy_permissions, only: %i(copy_modal copy)
  before_action :set_inline_name_editing, only: %i(show)
  before_action :load_repository_row, only: %i(show)
  before_action :set_breadcrumbs_items, only: %i(index show)
  before_action :validate_file_type, only: %i(export_repository export_repositories)

  layout 'fluid'

  def index
    respond_to do |format|
      format.html do
        render 'index'
      end
      format.json do
        repositories = Lists::RepositoriesService.new(@repositories, params, user: current_user).call
        render json: repositories, each_serializer: Lists::RepositorySerializer, user: current_user,
               meta: pagination_dict(repositories)
      end
    end
  end

  def sidebar
    render json: {
      html: render_to_string(partial: 'repositories/sidebar', locals: {
                               repositories: @repositories,
                               archived: params[:archived] == 'true'
                             })
    }
  end

  def show
    respond_to do |format|
      format.html do
        current_team_switch(@repository.team) unless @repository.shared_with?(current_team)
        @display_edit_button = can_create_repository_rows?(@repository)
        @display_delete_button = can_delete_repository_rows?(@repository)
        @display_duplicate_button = can_create_repository_rows?(@repository)
        @snapshot_provisioning = @repository.repository_snapshots.provisioning.any?

        @busy_printer = LabelPrinter.where.not(current_print_job_ids: []).first
      end
      format.json do
        # render serialized repository json
        render json: @repository, serializer: RepositorySerializer
      end
    end
  end

  def table_toolbar
    render json: {
      html: render_to_string(partial: 'repositories/toolbar_buttons', locals: { view_mode: params[:view_mode]})
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
      html: render_to_string(partial: 'repositories/repository_table',
                             locals: {
                               repository: @repository,
                               repository_index_link: repository_table_index_path(@repository)
                             })
    }
  end

  def create_modal
    @repository = Repository.new
    render json: {
      html: render_to_string(partial: 'create_repository_modal', formats: :html)
    }
  end

  def share_modal
    render json: { html: render_to_string(partial: 'share_repository_modal', formats: :html) }
  end

  def shareable_teams
    teams = current_user.teams.order(:name) - [@repository.team]
    render json: teams, each_serializer: ShareableTeamSerializer, repository: @repository
  end

  def hide_reminders
    # synchronously hide currently visible reminders
    if params[:visible_reminder_repository_row_ids].present?
      repository_cell_ids =
        RepositoryCell.joins(:repository_row)
                      .where(repository_rows: { id: params[:visible_reminder_repository_row_ids] })
                      .where.not(id: current_user.hidden_repository_cell_reminders.select(:repository_cell_id))
                      .with_active_reminder(current_user).pluck(:id)

      HiddenRepositoryCellReminder.import(
        repository_cell_ids.map { |id| { repository_cell_id: id, user_id: current_user.id } }
      )
    end

    # offload the rest to background job
    HideRepositoryRemindersJob.perform_later(@repository, current_user.id)

    render json: { status: :ok }, status: :accepted
  end

  def create
    @repository = Repository.new(
      team: current_team,
      created_by: current_user
    )
    @repository.assign_attributes(repository_params)

    if @repository.save
      log_activity(:create_inventory)
      render json: { message: t('repositories.index.modal_create.success_flash_html', name: @repository.name) }
    else
      render json: @repository.errors, status: :unprocessable_entity
    end
  end

  def destroy_modal
    render json: {
      html: render_to_string(
        partial: 'delete_repository_modal',
        formats: :html
      )
    }
  end

  def archive
    service = Repositories::ArchiveRepositoryService.call(repositories: @repositories,
                                                          user: current_user,
                                                          team: current_team)
    if service.succeed?
      render json: { message: t('repositories.archive_inventories.success_flash') }, status: :ok
    else
      render json: { message: service.error_message }, status: :unprocessable_entity
    end
  end

  def restore
    service = Repositories::RestoreRepositoryService.call(repositories: @repositories,
                                                          user: current_user,
                                                          team: current_team)
    if service.succeed?
      render json: { message: t('repositories.restore_inventories.success_flash') }, status: :ok
    else
      render json: { message: service.error_message }, status: :unprocessable_entity
    end
  end

  def destroy
    log_activity(:delete_inventory) # Log before delete id

    @repository.discard
    @repository.destroy_discarded(current_user.id)

    render json: {
      message: t('repositories.index.delete_flash', name: @repository.name)
    }
  end

  def rename_modal
    render json: {
      html: render_to_string(partial: 'rename_repository_modal', formats: :html)
    }
  end

  def update
    @repository.update(repository_params)

    if @repository.save
      log_activity(:rename_inventory) # Acton only for renaming

      render json: { url: team_repositories_path }
    else
      render json: @repository.errors, status: :unprocessable_entity
    end
  end

  def copy_modal
    @tmp_repository = Repository.new(
      team: current_team,
      created_by: current_user,
      name: @repository.name
    )
    render json: {
      html: render_to_string(partial: 'copy_repository_modal', formats: :html)
    }
  end

  def copy
    @tmp_repository = Repository.new(
      team: current_team,
      created_by: current_user
    )
    @tmp_repository.assign_attributes(repository_params)

    if !@tmp_repository.valid?
      render json: @tmp_repository.errors, status: :unprocessable_entity
    else
      copied_repository = @repository.copy(current_user, @tmp_repository.name)
      old_repo_stock_column = @repository.repository_columns.find_by(data_type: 'RepositoryStockValue')
      copied_repo_stock_column = copied_repository.repository_columns.find_by(data_type: 'RepositoryStockValue')

      if old_repo_stock_column && copied_repo_stock_column
        old_repo_stock_column.repository_stock_unit_items.each do |item|
          copied_item = item.dup
          copied_repo_stock_column.repository_stock_unit_items << copied_item
        end
        copied_repository.save!
      end

      if !copied_repository
        render json: { name: ['Server error'] }, status: :unprocessable_entity
      else
        render json: {
          message: t('repositories.index.copy_flash', old: @repository.name, new: copied_repository.name)
        }
      end
    end
  end

  # AJAX actions
  def repository_table_index
    render json: ::RepositoryDatatable.new(view_context, @repository, nil, current_user)
  end

  def parse_sheet
    render_403 unless can_create_repository_rows?(@repository)

    unless import_params[:file]
      unprocessable_entity_repository_response(t('repositories.parse_sheet.errors.no_file_selected'))
      return
    end
    begin
      parsed_file = ImportRepository::ParseRepository.new(
        file: import_params[:file],
        repository: @repository,
        session: session
      )
      if parsed_file.too_large?
        render json: { error: t('general.file.size_exceeded', file_size: Rails.configuration.x.file_max_size_mb) },
               status: :unprocessable_entity
      elsif parsed_file.has_too_many_rows?
        render json: { error: t('repositories.import_records.error_message.items_limit',
                                items_size: Constants::IMPORT_REPOSITORY_ITEMS_LIMIT) }, status: :unprocessable_entity
      else
        @import_data = parsed_file.data

        if @import_data.header.blank? || @import_data.columns.blank?
          return render json: { error: t('repositories.parse_sheet.errors.empty_file') }, status: :unprocessable_entity
        end

        if (@temp_file = parsed_file.generate_temp_file)
          render json: { import_data: @import_data, temp_file: @temp_file }
        else
          render json: { error: t('repositories.parse_sheet.errors.temp_file_failure') }, status: :unprocessable_entity
        end
      end
    rescue ArgumentError, CSV::MalformedCSVError
      render json: { error: t('repositories.parse_sheet.errors.invalid_file', encoding: ''.encoding) },
             status: :unprocessable_entity
    rescue TypeError
      render json: { error: t('repositories.parse_sheet.errors.invalid_extension') }, status: :unprocessable_entity
    end
  end

  def import_records
    render_403 unless can_create_repository_rows?(Repository.accessible_by_teams(current_team)
                                                            .find_by(id: import_params[:id]))
    # Check if there exist mapping for repository record (it's mandatory)
    if import_params[:mappings].present? && import_params[:mappings].value?('-1')
      status = ImportRepository::ImportRecords
               .new(
                 temp_file: TempFile.find_by(id: import_params[:file_id]),
                 repository: Repository.accessible_by_teams(current_team).find_by(id: import_params[:id]),
                 mappings: import_params[:mappings],
                 session: session,
                 user: current_user,
                 can_edit_existing_items: import_params[:can_edit_existing_items],
                 should_overwrite_with_empty_cells: import_params[:should_overwrite_with_empty_cells],
                 preview: import_params[:preview]
               ).import!
      if status[:status] == :ok
        log_activity(:import_inventory_items, num_of_items: status[:nr_of_added])
        render json: import_params[:preview] ? status : {}, status: :ok
      else
        render json: {}, status: :unprocessable_entity
      end
    else
      render json: { error: t('repositories.import_records.error_message.mapping_error') },
             status: :unprocessable_entity
    end
  end

  def export_empty_repository
    col_ids = [-3, -4, -5, -6, -7, -8, -9, -10]
    col_ids << -11 if Repository.repository_row_connections_enabled?
    col_ids += @repository.repository_columns.map(&:id)

    xlsx = RepositoryXlsxExport.to_empty_xlsx(@repository, col_ids)

    send_data xlsx, filename: "empty_repository.xlsx", type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  end

  def export_repository
    if params[:row_ids] && params[:header_ids]
      RepositoryZipExportJob.perform_later(
        user_id: current_user.id,
        params: {
          repository_id: @repository.id,
          row_ids: params[:row_ids],
          header_ids: params[:header_ids]
        },
        file_type: params[:file_type]
      )
      update_user_export_file_type if current_user.settings[:repository_export_file_type] != params[:file_type]
      log_activity(:export_inventory_items)
      render json: { message: t('zip_export.export_request_success') }
    else
      render json: { message: t('zip_export.export_error') }, status: :unprocessable_entity
    end
  end

  def export_repositories
    repositories = Repository.viewable_by_user(current_user, current_team).where(id: params[:repository_ids])
    if repositories.present?
      RepositoriesExportJob
        .perform_later(params[:file_type], repositories.pluck(:id), user_id: current_user.id, team_id: current_team.id)
      update_user_export_file_type if current_user.settings[:repository_export_file_type] != params[:file_type]
      log_activity(:export_inventories, inventories: repositories.pluck(:name).join(', '))
      render json: { message: t('zip_export.export_request_success') }
    else
      render json: { message: t('zip_export.export_error') }, status: :unprocessable_entity
    end
  end

  def export_repository_stock_items
    repository_rows = @repository.repository_rows.where(id: params[:row_ids]).pluck(:id, :name)
    if repository_rows.any?
      RepositoryStockZipExportJob.perform_later(
        user_id: current_user.id,
        params: {
          repository_row_ids: repository_rows.map { |row| row[0] }
        }
      )
      log_activity(
        :export_inventory_stock_consumption,
        inventory_items: repository_rows.map { |row| row[1] }.join(', ')
      )
      render json: { message: t('zip_export.export_request_success') }
    else
      render json: { message: t('zip_export.export_error') }, status: :unprocessable_entity
    end
  end

  def export_repository_stock_items_modal
    render json: {
      export_consumption_url: export_repository_stock_items_team_path(@repository),
      name: @repository.name
    }
  end

  def assigned_my_modules
    my_modules = MyModule.joins(:repository_rows).where(repository_rows: { repository: @repository })
                         .readable_by_user(current_user).distinct
    render json: {data: grouped_by_prj_exp(my_modules).map { |g|
                          {
                            label: "#{g[:project_name]} / #{g[:experiment_name]}", options: g[:tasks].map do |t|
                              { label: t.name, value: t.id }
                            end
                          }
                        } }
  end

  def repository_users
    rows_type = params[:archived_by].present? ? :archived_repository_rows : :created_repository_rows
    users = User.joins(rows_type)
                .where(rows_type => { repository: @repository })
                .group(:id)

    render json: { users: users.map do |u|
                            {
                              label: u.full_name,
                              value: u.id,
                              params: {
                                email: u.email, avatar_url: u.avatar_url('icon_small')
                              }
                            }
                          end }
  end

  def actions_toolbar
    render json: {
      actions:
        Toolbars::RepositoriesService.new(
          current_user,
          current_team,
          repository_ids: JSON.parse(params[:items]).map { |i| i['id'] }
        ).actions
    }
  end

  private

  def load_repository
    repository_id = params[:id] || params[:repository_id]
    @repository = Repository.accessible_by_teams(current_user.teams).find_by(id: repository_id)
    render_404 unless @repository
  end

  def load_repositories
    @repositories = Repository.accessible_by_teams(current_team)
  end

  def load_repositories_for_archiving
    @repositories = current_team.repositories.active.where(id: params[:repository_ids])
  end

  def load_repositories_for_restoring
    @repositories = current_team.repositories.archived.where(id: params[:repository_ids])
  end

  def load_repository_row
    @repository_row = nil
    @repository_row_landing_page = true if params[:landing_page].present?
    return if params[:row_id].blank?

    @repository_row = @repository.repository_rows.find_by(id: params[:row_id])
  end

  def set_inline_name_editing
    return unless can_manage_repository?(@repository)

    @inline_editable_title_config = {
      name: 'title',
      params_group: 'repository',
      item_id: @repository.id,
      field_to_udpate: 'name',
      path_to_update: team_repository_path(@repository),
      label_after:
        sanitize_input(
          "<span class=\"repository-share-icon\">#{inventory_shared_status_icon(@repository, current_team)}</span>"
        )
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

  def check_delete_permissions
    render_403 unless can_delete_repository?(@repository)
  end

  def check_share_permissions
    render_403 unless can_share_repository?(@repository)
  end

  def repository_params
    params.require(:repository).permit(:name)
  end

  def import_params
    params.permit(:id, :file, :file_id, :preview, :can_edit_existing_items,
                  :should_overwrite_with_empty_cells, :preview, mappings: {}).to_h
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
    if @repository.present?
      message_items = { repository: @repository.id }.merge(message_items)

      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @repository,
              team: @repository.team,
              message_items: message_items)
    else
      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @current_team,
              team: @current_team,
              message_items: message_items)
    end
  end

  def set_breadcrumbs_items
    @breadcrumbs_items = []
    archived_branch = @repository&.archived? || (!@repository && params[:view_mode] == 'archived')

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.inventories'),
                              url: archived_branch ? repositories_path(view_mode: 'archived') : repositories_path,
                              archived: archived_branch
                            })

    if @repository
      @breadcrumbs_items.push({
                                label: @repository.name,
                                url: repository_path(@repository),
                                archived: archived_branch
                              })
    end

    @breadcrumbs_items.each do |item|
      item[:label] = "(A) #{item[:label]}" if item[:archived]
    end
  end

  def validate_file_type
    render json: { message: 'Invalid file type' }, status: :bad_request unless %w(csv xlsx).include?(params[:file_type])
  end

  def update_user_export_file_type
    current_user.update_simple_setting(key: 'repository_export_file_type', value: params[:file_type])
  end
end
