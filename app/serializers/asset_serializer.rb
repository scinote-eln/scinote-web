# frozen_string_literal: true

class AssetSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include FileIconsHelper
  include ActionView::Helpers::NumberHelper

  attributes :file_name, :view_mode, :icon, :urls, :updated_at, :file_size, :medium_preview

  def icon
    file_fa_icon_class(object)
  end

  def file_name
    object.render_file_name
  end

  def updated_at
    I18n.l(object.updated_at, format: :full_date) if object.updated_at
  end

  def file_size
    number_to_human_size(object.file_size)
  end

  def medium_preview
    object.medium_preview if object.previewable?
  end

  def urls
    {
      blob: rails_blob_path(object.file, disposition: 'attachment'),
      preview: asset_file_preview_path(object)
    }
  end
end
