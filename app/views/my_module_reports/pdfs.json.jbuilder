# frozen_string_literal: true

json.data do
  json.array! @assets.each do |asset|
    json.id asset.id
    json.file_name asset.render_file_name
    json.medium_preview rails_representation_url(asset.medium_preview)
    json.preview asset_file_preview_path(asset)
    if asset.step
      json.parent_name I18n.t('my_modules.reports.wizard.first_step.asset_from_step', name: asset.step.name)
    else
      json.parent_name I18n.t('my_modules.reports.wizard.first_step.asset_from_result', name: asset.result.name)
    end
  end
end
