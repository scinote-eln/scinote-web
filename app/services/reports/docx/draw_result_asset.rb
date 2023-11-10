# frozen_string_literal: true

module Reports::Docx::DrawResultAsset
  def draw_result_asset(result, settings)
    result.assets.each do |asset|
      timestamp = asset.created_at
      asset_url = Rails.application.routes.url_helpers.asset_download_url(asset)
      color = @color
      @docx.p

      begin
        Reports::DocxRenderer.render_asset_image(@docx, asset) if asset.previewable? && !asset.list?
      rescue StandardError => e
        Rails.logger.error e.message
        @docx.p do
          text I18n.t('projects.reports.index.generation.file_preview_generation_error'), italic: true
        end
      end

      @docx.p do
        text result.name.presence || I18n.t('projects.reports.unnamed'), italic: true
        text ' '
        link I18n.t('projects.reports.elements.download'), asset_url do
          italic true
        end
        text "  #{I18n.t('search.index.archived')} ", bold: true if result.archived?
        text ' ' + I18n.t('projects.reports.elements.result_asset.file_name', file: asset.file_name)
        text ' ' + I18n.t('projects.reports.elements.result_asset.user_time',
                          user: result.user.full_name, timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]

        if settings.dig(:task, :file_results_previews) && ActiveStorageFileUtil.previewable_document?(asset&.file&.blob)
          text " #{I18n.t('projects.reports.elements.result_asset.full_preview_attached')}", color: color[:gray]
        end
      end

      draw_result_comments(result) if @settings.dig('task', 'result_comments')
    end
  end
end
