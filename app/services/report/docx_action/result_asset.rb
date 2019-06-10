# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::ResultAsset
  def draw_result_asset(result, children)
    asset = result.asset
    is_image = result.asset.is_image?
    timestamp = asset.created_at
    @docx.p
    @docx.p do
      text result.name
      text ' ' + I18n.t('search.index.archived'), color: 'a0a0a0' if result.archived?
      text  ' ' + I18n.t('projects.reports.elements.result_asset.file_name', file: asset.file_file_name)
      text  ' ' + I18n.t('projects.reports.elements.result_asset.user_time',
                         user: result.user.full_name, timestamp: I18n.l(timestamp, format: :full)), color: 'a0a0a0'
    end

    asset_image_preparing(asset) if is_image

    children.each do |result_hash|
      draw_result_comments(result, result_hash['sort_order']) if result_hash['type_of'] == 'result_comments'
    end
  end
end

# rubocop:enable  Style/ClassAndModuleChildren
