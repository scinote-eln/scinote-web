# frozen_string_literal: true

module ReportActions
  class SavePdfToInventoryItem

    attr_reader :cell_value

    def initialize(user, team, params)
      @user   = user
      @team   = team
      @params = params
      load_repository_collaborators
    end

    def call
      file  = generate_pdf(@params[:html])
      asset = create_new_asset(file)
      cell  = fetch_repository_cell
      cell.destroy if cell
      @cell_value = create_new_cell_value(asset)
    end

    private

    include Canaid::Helpers::PermissionsHelper

    def load_repository_collaborators
      @repository        = Repository.find_by_id(@params[:repository_id])
      @repository_column = RepositoryColumn.find_by_id(
        @params[:respository_column_id]
      )
      @repository_item   = RepositoryRow.find_by_id(
        @params[:repository_item_id]
      )
      unless can_create_repository_rows?(@user, @repository.team)
        raise ReportActions::RepositoryPermissionError,
                I18n.t('projects.reports.new.no_permissions')
      end
    end

    def generate_pdf(content)
      ac = ActionView::Base.new(ActionController::Base.view_paths, {})
      ac.extend ReportsHelper # include reports helper methods to view
      ac.extend InputSanitizeHelper # include input sanitize methods to view
      no_content_label = I18n.t('projects.reports.new.no_content_for_PDF_html')
      save_path        = Tempfile.open(['report', '.pdf'], Rails.root.join('tmp'))
      content          = no_content_label if content.blank?
      pdf_file         = WickedPdf.new.pdf_from_string(
        ac.render(template: 'reports/report.pdf.erb',
                  locals: { content: content }),
        header: { right: '[page] of [topage]' },
        disable_javascript: true
      )
      File.open(save_path, 'wb') do |file|
        file << pdf_file
      end
      save_path
    end

    def create_new_asset(file)
      asset = Asset.new(
        file: file, created_by: @user, last_modified_by: @user, team: @team
      )
      asset.post_process_file(@team) if asset.save
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
  end

  RepositoryPermissionError = Class.new(StandardError)
end
