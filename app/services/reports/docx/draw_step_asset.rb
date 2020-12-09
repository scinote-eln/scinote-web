# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawStepAsset
<<<<<<< HEAD
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
=======
module Reports::Docx::DrawStepAsset
>>>>>>> Initial commit of 1.17.2 merge
  def draw_step_asset(subject)
    asset = Asset.find_by_id(subject['id']['asset_id'])
=======
  def draw_step_asset(subject, step)
    asset = step.assets.find_by(id: subject['id']['asset_id'])
>>>>>>> Pulled latest release
    return unless asset

    timestamp = asset.created_at
    asset_url = Rails.application.routes.url_helpers.asset_download_url(asset)
    color = @color
    @docx.p
    @docx.p do
<<<<<<< HEAD
      text (I18n.t 'projects.reports.elements.step_asset.file_name', file: asset.file_file_name), italic: true
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
      text (I18n.t 'projects.reports.elements.step_asset.file_name', file: asset.file_name), italic: true
>>>>>>> Initial commit of 1.17.2 merge
      text ' '
      link I18n.t('projects.reports.elements.download'), asset_url do
        italic true
      end
      text ' '
      text I18n.t('projects.reports.elements.step_asset.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end

<<<<<<< HEAD
<<<<<<< HEAD
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
=======
    asset_image_preparing(asset) if asset.image?
>>>>>>> Initial commit of 1.17.2 merge
=======
    Reports::DocxRenderer.render_asset_image(@docx, asset) if asset.previewable? && !asset.list?
>>>>>>> Pulled latest release
  end
end
