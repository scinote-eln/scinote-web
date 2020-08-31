# frozen_string_literal: true

module ReportActions
  class SavePdfToInventoryItem
    def initialize(user, team, params)
      @user   = user
      @team   = team
      @params = params
      load_repository_collaborators
    end

    def save
      file_path  = generate_pdf(@params[:html])
      asset      = create_new_asset(file_path)
      cell       = fetch_repository_cell
      cell&.destroy
      @new_cell_value = create_new_cell_value(asset)
      @new_cell_value.save
      log_activity
    end

    def error_messages
      return I18n.t('general.error') unless @new_cell_value

      @new_cell_value.errors.full_messages.join
    end

    private

    include Canaid::Helpers::PermissionsHelper

    def load_repository_collaborators
      @repository        = load_repository
      @repository_column = load_repository_column
      @repository_item   = load_repository_item
      unless can_create_repository_rows?(@user, @repository)
        raise ReportActions::RepositoryPermissionError,
              I18n.t('projects.reports.new.no_permissions')
      end
    end

    def generate_pdf(content)
      file_path  = create_temporary_file
      pdf_file   = WickedPdf.new.pdf_from_string(
        action_view_context.render(
          template: 'reports/report.pdf.erb',
          locals: { content: prepare_pdf_content(content) }
        ),
        header: { right: '[page] of [topage]' },
        disable_javascript: true
      )
      File.open(file_path, 'wb') do |file|
        file << pdf_file
      end
      file_path
    end

    def create_new_asset(file_path)
      asset = Asset.create(created_by: @user, last_modified_by: @user, team: @team)
      asset.file.attach(io: file_path, filename: File.basename(file_path))
      asset
    end

    def fetch_repository_cell
      RepositoryCell.where(repository_row: @repository_item,
                           repository_column: @repository_column,
                           value_type: 'RepositoryAssetValue').first
    end

    def create_new_cell_value(asset)
      RepositoryAssetValue.new(
        asset: asset,
        created_by: @user,
        last_modified_by: @user,
        repository_cell_attributes: {
          repository_row: @repository_item,
          repository_column: @repository_column
        }
      )
    end

    def load_repository
      Repository.find_by(id: @params[:repository_id])
    end

    def load_repository_column
      RepositoryColumn.find_by(id: @params[:respository_column_id])
    end

    def load_repository_item
      RepositoryRow.find_by(id: @params[:repository_item_id])
    end

    def action_view_context
      av = ActionView::Base.new(ActionController::Base.view_paths, {})
      av.extend ReportsHelper # include reports helper methods to view
      av.extend InputSanitizeHelper # include input sanitize methods to view
      av
    end

    def create_temporary_file
      Tempfile.open(['report', '.pdf'], Rails.root.join('tmp'))
    end

    def prepare_pdf_content(content)
      return content if content.present?

      I18n.t('projects.reports.new.no_content_for_PDF_html')
    end

    def log_activity
      Activities::CreateActivityService
        .call(activity_type: :edit_item_inventory,
              owner: @user,
              subject: @repository,
              team: @team,
              message_items: {
                repository_row: @repository_item.id,
                repository: @repository.id
              })
    end
  end

  RepositoryPermissionError = Class.new(StandardError)
end
