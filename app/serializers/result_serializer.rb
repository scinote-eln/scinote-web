# frozen_string_literal: true

class ResultSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper

  attributes :name, :id, :urls, :updated_at, :created_at_formatted, :updated_at_formatted, :user,
             :my_module_id, :attachments_manageble, :marvinjs_enabled, :marvinjs_context, :type,
             :wopi_enabled, :wopi_context, :created_at, :created_by, :archived, :assets_order,
             :open_vector_editor_context, :comments_count, :assets_view_mode, :storage_limit

  def marvinjs_enabled
    MarvinJsService.enabled?
  end

  def type
    'Result'
  end

  def name
    if archived
      "(A) #{object.name}"
    else
      object.name
    end
  end

  def archived
    object.archived?
  end

  def current_user
    scope
  end

  def storage_limit
    nil
  end

  def marvinjs_context
    if marvinjs_enabled
      {
        marvin_js_asset_url: marvin_js_assets_path,
        icon: image_path('icon_small/marvinjs.svg')
      }
    end
  end

  def updated_at
    object.updated_at.to_i
  end

  def user
    {
      avatar: object.user&.avatar_url(:icon_small),
      name: object.user&.full_name
    }
  end

  def assets_order
    object.current_view_state(current_user).state.dig('assets', 'sort') unless object.destroyed?
  end

  def attachments_manageble
    can_manage_result?(object)
  end

  def comments_count
    object.comments.count
  end

  def wopi_enabled
    wopi_enabled?
  end

  def wopi_context
    if wopi_enabled
      {
        create_wopi: create_wopi_file_path,
        icon: image_path('office/office.svg')
      }
    end
  end

  def open_vector_editor_context
    if can_manage_result?(object)
      {
        new_sequence_asset_url: new_gene_sequence_asset_url(parent_type: 'Result', parent_id: object.id),
        icon: image_path('icon_small/sequence-editor.svg')
      }
    end
  end

  def created_at_formatted
    I18n.l(object.created_at, format: :full)
  end

  def updated_at_formatted
    I18n.l(object.updated_at, format: :full)
  end

  def urls
    urls_list = {
      elements_url: elements_my_module_result_path(object.my_module, object),
      attachments_url: assets_my_module_result_path(object.my_module, object)
    }

    if can_manage_result?(object)
      urls_list.merge!({
                         archive_url: archive_my_module_result_path(object.my_module, object),
                         update_url: my_module_result_path(object.my_module, object),
                         create_table_url: my_module_result_tables_path(object.my_module, object),
                         create_text_url: my_module_result_texts_path(object.my_module, object),
                         update_asset_view_mode_url: update_asset_view_mode_my_module_result_path(object.my_module,
                                                                                                  object),
                         update_view_state_url: update_view_state_my_module_result_path(object.my_module, object),
                         direct_upload_url: rails_direct_uploads_url,
                         upload_attachment_url: upload_attachment_my_module_result_path(object.my_module, object),
                         reorder_elements_url: reorder_my_module_result_result_orderable_elements_path(
                           object.my_module, object
                         )
                       })
    end

    urls_list[:restore_url] = restore_my_module_result_path(object.my_module, object) if can_restore_result?(object)
    urls_list[:delete_url] = my_module_result_path(object.my_module, object) if can_delete_result?(object)
    if can_create_results?(object.my_module)
      urls_list[:duplicate_url] =
        duplicate_my_module_result_url(object.my_module, object)
    end

    urls_list
  end

  def created_at
    object.created_at.strftime('%B %d, %Y at %H:%M')
  end

  def created_by
    object.user.full_name
  end
end
