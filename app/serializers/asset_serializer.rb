# frozen_string_literal: true

class AssetSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include FileIconsHelper
  include ActionView::Helpers::NumberHelper
  include InputSanitizeHelper
  include ApplicationHelper

  attributes :file_name, :file_extension, :view_mode, :icon, :urls, :updated_at_formatted,
             :file_size, :medium_preview, :large_preview, :asset_type, :wopi, :file_name_without_extension,
             :wopi_context, :pdf_previewable, :file_size_formatted, :asset_order,
             :updated_at, :metadata, :image_editable, :image_context, :pdf, :attached, :parent_type,
             :edit_version_range
  attribute :checksum, if: :sync_url_present?

  def icon
    file_fa_icon_class(object)
  end

  def file_name
    object.render_file_name
  end

  def file_name_without_extension
    File.basename(object.file_name, '.*')
  end

  def file_extension
    File.extname(object.file_name)[1..]
  end

  def updated_at
    object.updated_at.to_i
  end

  def updated_at_formatted
    I18n.l(object.updated_at, format: :full_with_comma) if object.updated_at
  end

  def parent_type
    return 'step' if object.step
    return 'result' if object.result
  end

  def attached
    object.file.attached?
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
        wopi_icon: ActionController::Base.helpers.image_path(file_application_url(object)),
        sn_icon: sn_icon_for(object)
      }
    end
  end

  def pdf_previewable
    object.pdf_previewable?
  end

  def pdf
    return unless object.pdf? || object.file_pdf_preview.attached?

    {
      url: object.pdf? ? asset_download_path(object) : asset_pdf_preview_path(object),
      size: object.pdf? ? object.file_size : object.file_pdf_preview&.blob&.byte_size,
      worker_url: ActionController::Base.helpers.asset_path('pdf_js_worker.js')
    }
  end

  def image_editable
    @image_editable ||= object.editable_image?
  end

  def checksum
    object.file.checksum
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

  def edit_version_range
    { min: Constants::MIN_SCINOTE_EDIT_VERSION, max: Constants::MAX_SCINOTE_EDIT_VERSION }
  end

  def urls
    urls = {
      preview: asset_file_preview_path(object),
      download: (asset_download_path(object) if attached),
      load_asset: load_asset_path(object),
      asset_file: asset_file_url_path(object),
      marvin_js: marvin_js_asset_path(object),
      marvin_js_icon: image_path('icon_small/marvinjs.svg'),
      versions: (asset_versions_path(object) if attached)
    }
    user = scope[:user] || @instance_options[:user]
    if managable?
      urls.merge!(
        toggle_view_mode: toggle_view_mode_path(object),
        edit_asset: edit_asset_path(object),
        marvin_js_start_edit: start_editing_marvin_js_asset_path(object),
        start_edit_image: start_edit_image_path(object),
        delete: asset_destroy_path(object),
        duplicate: asset_duplicate_path(object),
        move_targets: asset_move_tagets_path(object),
        move: asset_move_path(object),
        rename: asset_rename_path(object)
      )
    end

    urls[:restore_version] = asset_restore_version_path(object) if can_restore_asset?(user, object)
    urls[:open_vector_editor_edit] = edit_gene_sequence_asset_path(object.id) if managable?

    if managable? && can_open_asset_locally?(user, object)
      urls[:open_locally] = asset_sync_show_path(object)
      urls[:open_locally_api] = Constants::ASSET_SYNC_URL
      urls[:asset_show] = asset_show_path(object)
      urls[:asset_checksum] = asset_checksum_path(object)
    end

    urls[:wopi_action] = object.get_action_url(user, 'embedview') if wopi && can_read_asset?(user, object)
    urls[:blob] = rails_blob_path(object.file, disposition: 'attachment') if object.file.attached?

    urls
  end

  def sync_url_present?
    user = scope[:user] || @instance_options[:user]
    can_open_asset_locally?(user, object)
  end

  private

  def managable?
    return true if @instance_options[:managable_step] || @instance_options[:managable_result]

    user = scope[:user] || @instance_options[:user]
    @managable ||= can_manage_asset?(user, object)
  end
end
