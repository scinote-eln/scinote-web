# frozen_string_literal: true

<<<<<<< HEAD
module Reports::Docx::DrawStepAsset
  def draw_step_asset(asset)
    timestamp = asset.created_at
    asset_url = Rails.application.routes.url_helpers.asset_download_url(asset)
    color = @color
    @docx.p
    @docx.p do
      text (I18n.t 'projects.reports.elements.step_asset.file_name', file: asset.file_name), italic: true
      text ' '
      link I18n.t('projects.reports.elements.download'), asset_url do
        italic true
      end
=======
module DrawStepAsset
  def draw_step_asset(subject)
    asset = Asset.find_by_id(subject['id']['asset_id'])
    return unless asset

    is_image = asset.is_image?
    timestamp = asset.created_at
    color = @color
    @docx.p
    @docx.p do
      text (I18n.t 'projects.reports.elements.step_asset.file_name', file: asset.file_file_name), italic: true
>>>>>>> Finished merging. Test on dev machine (iMac).
      text ' '
      text I18n.t('projects.reports.elements.step_asset.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end

<<<<<<< HEAD
    begin
      Reports::DocxRenderer.render_asset_image(@docx, asset) if asset.previewable? && !asset.list?
    rescue StandardError => e
      Rails.logger.error e.message
      @docx.p do
        text I18n.t('projects.reports.index.generation.file_preview_generation_error'), italic: true
      end
    end
=======
    asset_image_preparing(asset) if is_image
>>>>>>> Finished merging. Test on dev machine (iMac).
  end
end
