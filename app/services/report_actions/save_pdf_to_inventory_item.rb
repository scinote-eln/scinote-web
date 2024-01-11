# frozen_string_literal: true

module ReportActions
  class SavePdfToInventoryItem
    def initialize(report, user, team, params)
      @report = report
      @user   = user
      @team   = team
      @params = params
      load_repository_collaborators
    end

    def save
      # we lock the row, to prevent two repository cells being created at the same location
      # as the RepositoryCell validation would pass in both concurrent transactions

      @repository_row.with_lock do
        asset = create_new_asset
        delete_old_repository_cell
        @new_cell_value = create_new_cell_value(asset)
        log_activity
      end
    end

    def error_messages
      return I18n.t('general.error') unless @new_cell_value

      @new_cell_value.errors.full_messages.join
    end

    private

    include Canaid::Helpers::PermissionsHelper

    def load_repository_collaborators
      @repository = Repository.active.accessible_by_teams(@team).find_by(id: @params[:repository_id])
      unless can_create_repository_rows?(@user, @repository)
        raise ReportActions::RepositoryPermissionError, I18n.t('projects.reports.new.no_permissions')
      end

      @repository_column = @repository.repository_columns.find(@params[:repository_column_id])
      @repository_row = @repository.repository_rows.find(@params[:repository_item_id])
    end

    def create_new_asset
      asset = Asset.create(created_by: @user, last_modified_by: @user, team: @team)
      asset.file.attach(@report.pdf_file.blob)
      asset
    end

    def delete_old_repository_cell
      @repository_row.repository_cells.find_by(repository_column: @repository_column)&.destroy
    end

    def create_new_cell_value(asset)
      RepositoryAssetValue.create!(
        asset: asset,
        created_by: @user,
        last_modified_by: @user,
        repository_cell_attributes: {
          repository_row: @repository_row,
          repository_column: @repository_column
        }
      )
    end

    def log_activity
      Activities::CreateActivityService
        .call(activity_type: :edit_item_inventory,
              owner: @user,
              subject: @repository_row,
              team: @team,
              message_items: {
                repository_row: @repository_row.id,
                repository: @repository.id
              })
    end
  end

  RepositoryPermissionError = Class.new(StandardError)
end
