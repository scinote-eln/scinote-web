# frozen_string_literal: true

json.data do
  json.array! @asset_groups do |group|
    parent = group[:parent]

    json.id parent.id
    json.type group[:type]
    json.name I18n.t("my_modules.reports.wizard.first_step.#{group[:type]}_group", name: parent.name)
    json.assets group[:assets] do |asset|
      json.id asset.id
      json.file_name asset.render_file_name
      json.file_title asset.file_title
      json.medium_preview rails_representation_url(asset.medium_preview)
      json.preview asset_file_preview_path(asset)
    end
  end
end
