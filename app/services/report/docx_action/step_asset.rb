# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::StepAsset
  def draw_step_asset(asset)
    is_image = asset.is_image?
    timestamp = asset.created_at
    @docx.p
    @docx.p do
      text I18n.t 'projects.reports.elements.step_asset.file_name', file: asset.file_file_name
      text ' '
      text I18n.t('projects.reports.elements.step_asset.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: 'a0a0a0'
    end

    asset_image_preparing(asset) if is_image
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
