# frozen_string_literal: true

module Reports::Docx::DrawResultAsset
  def draw_result_asset(subject)
    result = Result.find_by_id(subject['id']['result_id'])
    return unless result

    asset = result.asset
    timestamp = asset.created_at
    color = @color
    @docx.p
    @docx.p do
      text result.name, italic: true
      text ' ' + I18n.t('search.index.archived'), color: color[:gray] if result.archived?
      text ' ' + I18n.t('projects.reports.elements.result_asset.file_name', file: asset.file_name)
      text ' ' + I18n.t('projects.reports.elements.result_asset.user_time',
                        user: result.user.full_name, timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end

    asset_image_preparing(asset) if asset.image?

    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
  end
end
