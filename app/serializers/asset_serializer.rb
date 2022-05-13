# frozen_string_literal: true

class AssetSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include FileIconsHelper
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  attributes :file_name, :view_mode, :icon, :urls, :updated_at, :file_size, :medium_preview, :asset_type, :wopi,
             :pdf_previewable, :file_size_formatted

  def icon
    file_fa_icon_class(object)
  end

  def file_name
    object.render_file_name
  end

  def updated_at
    I18n.l(object.updated_at, format: :full_date) if object.updated_at
  end

  def file_size_formatted
    number_to_human_size(object.file_size)
  end

  def medium_preview
    rails_representation_url(object.medium_preview) if object.previewable?
  end

  def large_preview
    rails_representation_url(object.large_preview) if object.previewable?
  end

  def asset_type
    object.file.metadata&.dig(:asset_type)
  end

  def wopi
    wopi_enabled? && wopi_file?(object)
  end

  def pdf_previewable
    object.pdf_previewable? if object.file.attached?
  end

  def urls
    urls = {
      preview: asset_file_preview_path(object),
      load_asset: load_asset_path(object)
    }
    urls[:wopi_action] = object.get_action_url(@instance_options[:user], 'embedview') if wopi
    urls[:blob] = rails_blob_path(object.file, disposition: 'attachment') if object.file.attached?

    urls
  end
end
