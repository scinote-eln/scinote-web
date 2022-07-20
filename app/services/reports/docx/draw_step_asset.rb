# frozen_string_literal: true

module Reports::Docx::DrawStepAsset
  def draw_step_asset(asset)
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
      text (I18n.t 'projects.reports.elements.step_asset.file_name', file: asset.file_name), italic: true
      text ' '
      link I18n.t('projects.reports.elements.download'), asset_url do
        italic true
      end
      text ' '
      text I18n.t('projects.reports.elements.step_asset.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
  end
end
