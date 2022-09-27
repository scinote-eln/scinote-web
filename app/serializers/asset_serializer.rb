# frozen_string_literal: true

class AssetSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include Webpacker::Helper
  include FileIconsHelper
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper

  attributes :file_name, :view_mode, :icon, :urls, :updated_at_formatted,
             :file_size, :medium_preview, :large_preview, :asset_type, :wopi,
             :wopi_context, :pdf_previewable, :file_size_formatted, :asset_order,
             :updated_at, :metadata, :image_editable, :image_context, :pdf

  def icon
    file_fa_icon_class(object)
  end

  def file_name
    object.render_file_name
  end

  def updated_at
    object.updated_at.to_i
  end

  def updated_at_formatted
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

  def metadata
    object.file.metadata
  end

  def wopi
    wopi_enabled? && wopi_file?(object)
  end

  def wopi_context
    if wopi
      edit_supported, title = wopi_file_edit_button_status(object)
      {
        edit_supported: edit_supported,
        title: title,
        button_text: wopi_button_text(object, 'edit'),
        wopi_icon: ActionController::Base.helpers.image_path(file_application_url(object))
      }
    end
  end

  def pdf_previewable
    object.pdf_previewable? if object.file.attached?
  end

  def pdf
    return unless object.pdf?

    {
      url: object.pdf? ? asset_download_path(object) : asset_pdf_preview_path(object),
      size: !object.pdf? && object.pdf_preview_ready? ? object.file_pdf_preview&.blob&.byte_size : object.file_size,
      worker_url: asset_pack_path('pdfjs/pdf_js_worker.js')
    }
  end

  def image_editable
    object.editable_image?
  end

  def image_context
    if image_editable
      {
        quality: object.file_image_quality || 80,
        type: object.file.content_type
      }
    end
  end

  def asset_order
    case object.view_mode
    when 'inline'
      0
    when 'thumbnail'
      1
    when 'list'
      2
    end
  end

  def urls
    urls = {
      preview: asset_file_preview_path(object),
      download: rails_blob_path(object.file, disposition: 'attachment'),
      load_asset: load_asset_path(object),
      asset_file: asset_file_url_path(object),
      marvin_js: marvin_js_asset_path(object),
      marvin_js_icon: image_path('icon_small/marvinjs.svg')
    }
    user = scope[:user] || @instance_options[:user]
    if can_manage_asset?(user, object)
      urls.merge!(
        toggle_view_mode: toggle_view_mode_path(object),
        edit_asset: edit_asset_path(object),
        marvin_js_start_edit: start_editing_marvin_js_asset_path(object),
        start_edit_image: start_edit_image_path(object),
        delete: asset_destroy_path(object)
      )
    end
    urls[:wopi_action] = object.get_action_url(user, 'embedview') if wopi && can_manage_asset?(user, object)
    urls[:blob] = rails_blob_path(object.file, disposition: 'attachment') if object.file.attached?

    urls
  end
end
