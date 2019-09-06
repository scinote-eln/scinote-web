# frozen_string_literal: true

<<<<<<< HEAD
module Reports::Docx::DrawResultAsset
  def draw_result_asset(result)
    asset = result.asset
    timestamp = asset.created_at
    asset_url = Rails.application.routes.url_helpers.asset_download_url(asset)
=======
module DrawResultAsset
  def draw_result_asset(subject)
    result = Result.find_by_id(subject['id']['result_id'])
    return unless result

    asset = result.asset
    is_image = result.asset.is_image?
    timestamp = asset.created_at
>>>>>>> Finished merging. Test on dev machine (iMac).
    color = @color
    @docx.p
    @docx.p do
      text result.name, italic: true
<<<<<<< HEAD
      text ' '
      link I18n.t('projects.reports.elements.download'), asset_url do
        italic true
      end
      text ' ' + I18n.t('search.index.archived'), color: color[:gray] if result.archived?
      text ' ' + I18n.t('projects.reports.elements.result_asset.file_name', file: asset.file_name)
      text ' ' + I18n.t('projects.reports.elements.result_asset.user_time',
                        user: result.user.full_name, timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end

    begin
      Reports::DocxRenderer.render_asset_image(@docx, asset) if asset.previewable? && !asset.list?
    rescue StandardError => e
      Rails.logger.error e.message
      @docx.p do
        text I18n.t('projects.reports.index.generation.file_preview_generation_error'), italic: true
      end
    end

    draw_result_comments(result) if @settings.dig('task', 'result_comments')
=======
      text ' ' + I18n.t('search.index.archived'), color: color[:gray] if result.archived?
      text ' ' + I18n.t('projects.reports.elements.result_asset.file_name', file: asset.file_file_name)
      text ' ' + I18n.t('projects.reports.elements.result_asset.user_time',
                         user: result.user.full_name, timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end

    asset_image_preparing(asset) if is_image

    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
>>>>>>> Finished merging. Test on dev machine (iMac).
  end
end
