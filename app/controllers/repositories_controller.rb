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
  before_action :set_breadcrumbs_items, only: %i(index show)

  layout 'fluid'

  def index
    respond_to do |format|
      format.html do
        render 'index'
      end
      format.json do
        repositories = Lists::RepositoriesService.new(@repositories, params).call
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
    current_team_switch(@repository.team) unless @repository.shared_with?(current_team)
    @display_edit_button = can_create_repository_rows?(@repository)
    @display_delete_button = can_delete_repository_rows?(@repository)
    @display_duplicate_button = can_create_repository_rows?(@repository)
    @snapshot_provisioning = @repository.repository_snapshots.provisioning.any?

    @busy_printer = LabelPrinter.where.not(current_print_job_ids: []).first
  end

  def table_toolbar
    render json: {
      html: render_to_string(partial: 'repositories/toolbar_buttons')
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

  def export_modal
    if current_user.has_available_exports?
      render json: {
        html: render_to_string(
          partial: 'export_repositories_modal',
          locals: { team_name: current_team.name,
                    counter: params[:counter].to_i,
                    export_limit: TeamZipExport.exports_limit,
                    num_of_requests_left: current_user.exports_left - 1 },
          formats: :html
        )
      }
    else
      render json: {
        html: render_to_string(
          partial: 'export_limit_exceeded_modal',
          locals: { requests_limit: TeamZipExport.exports_limit },
          formats: :html
        )
      }
    end
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

        if @import_data.header.blank? || @import_data.columns.blank?
          return repository_response(t('repositories.parse_sheet.errors.empty_file'))
        end

        if (@temp_file = parsed_file.generate_temp_file)
          render json: {
            html: render_to_string(partial: 'repositories/parse_records_modal', formats: :html)
          }
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
          partial: 'shared/flash_errors',
          formats: :html,
          locals: { error_title: t('repositories.import_records.error_message.errors_list_title'),
                    error: t('repositories.import_records.error_message.no_repository_name') }
        )
      }, status: :unprocessable_entity
    end
  end

  def export_repository
    if params[:row_ids] && params[:header_ids]
      RepositoryZipExportJob.perform_later(
        user_id: current_user.id,
        params: {
          repository_id: @repository.id,
          row_ids: params[:row_ids],
          header_ids: params[:header_ids]
        }
      )
      log_activity(:export_inventory_items)
      render json: { message: t('zip_export.export_request_success') }
    else
      render json: { message: t('zip_export.export_error') }, status: :unprocessable_entity
    end
  end

  def export_repositories
    repositories = Repository.viewable_by_user(current_user, current_team).where(id: params[:repository_ids])
    if repositories.present? && current_user.has_available_exports?
      current_user.increase_daily_exports_counter!
      RepositoriesExportJob.perform_later(repositories.pluck(:id), user_id: current_user.id, team_id: current_team.id)
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
    archived_branch = @repository&.archived? || (!@repository && params[:archived] == 'true')

    @breadcrumbs_items.push({
                              label: t('breadcrumbs.inventories'),
                              url: archived_branch ? repositories_path(archived: true) : repositories_path,
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
end
