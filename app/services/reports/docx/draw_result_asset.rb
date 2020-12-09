# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawResultAsset
<<<<<<< HEAD
  def draw_result_asset(result)
    asset = result.asset
    timestamp = asset.created_at
    asset_url = Rails.application.routes.url_helpers.asset_download_url(asset)
=======
module DrawResultAsset
=======
module Reports::Docx::DrawResultAsset
>>>>>>> Initial commit of 1.17.2 merge
  def draw_result_asset(subject)
    result = Result.find_by_id(subject['id']['result_id'])
=======
  def draw_result_asset(subject, my_module)
    result = my_module.results.find_by(id: subject['id']['result_id'])
>>>>>>> Pulled latest release
    return unless result

    asset = result.asset
    timestamp = asset.created_at
<<<<<<< HEAD
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    asset_url = Rails.application.routes.url_helpers.asset_download_url(asset)
>>>>>>> Pulled latest release
    color = @color
    @docx.p
    @docx.p do
      text result.name, italic: true
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Pulled latest release
      text ' '
      link I18n.t('projects.reports.elements.download'), asset_url do
        italic true
      end
<<<<<<< HEAD
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
=======
>>>>>>> Pulled latest release
      text ' ' + I18n.t('search.index.archived'), color: color[:gray] if result.archived?
      text ' ' + I18n.t('projects.reports.elements.result_asset.file_name', file: asset.file_name)
      text ' ' + I18n.t('projects.reports.elements.result_asset.user_time',
                        user: result.user.full_name, timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end

    Reports::DocxRenderer.render_asset_image(@docx, asset) if asset.previewable? && !asset.list?

    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child, result)
    end
>>>>>>> Finished merging. Test on dev machine (iMac).
  end
end
