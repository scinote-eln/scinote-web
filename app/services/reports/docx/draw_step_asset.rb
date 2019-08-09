# frozen_string_literal: true

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
      text ' '
      text I18n.t('projects.reports.elements.step_asset.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end

    asset_image_preparing(asset) if is_image
  end
end
