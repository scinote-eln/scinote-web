# frozen_string_literal: true

class ResultTemplateSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper

  attributes :name, :id, :urls, :updated_at, :created_at_formatted, :updated_at_formatted, :user, :attachments_manageble, :marvinjs_enabled, :marvinjs_context, :type,
             :wopi_enabled, :wopi_context, :created_at, :created_by, :assets_order, :template,
             :open_vector_editor_context, :assets_view_mode, :storage_limit, :collapsed, :steps

  def collapsed
    result_template_states = current_user.settings.fetch('result_template_states', {})
    result_template_states[object.id.to_s] == true
  end

  def template
    true
  end

  def marvinjs_enabled
    MarvinJsService.enabled?
  end

  def steps
    []
  end

  def type
    'Result'
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
    can_manage_result_template?(object)
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
    if can_manage_result_template?(object)
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
      elements_url: elements_protocol_result_template_path(object.protocol, object),
      attachments_url: assets_protocol_result_template_path(object.protocol, object)
    }

    if can_manage_result_template?(object)
      urls_list.merge!({
                         update_url: protocol_result_template_path(object.protocol, object),
                         create_table_url: protocol_result_template_tables_path(object.protocol, object, template: true),
                         create_text_url: protocol_result_template_texts_path(object.protocol, object, template: true),
                         update_asset_view_mode_url: update_asset_view_mode_protocol_result_template_path(object.protocol,
                                                                                                          object),
                         update_view_state_url: update_view_state_protocol_result_template_path(object.protocol, object),
                         direct_upload_url: rails_direct_uploads_url,
                         upload_attachment_url: upload_attachment_protocol_result_template_path(object.protocol, object),
                         reorder_elements_url: reorder_protocol_result_template_result_template_orderable_elements_path(
                           object.protocol, object
                         )
                       })
    end

    urls_list[:delete_url] = protocol_result_template_path(object.protocol, object) if can_delete_result_template?(object)
    if can_create_result_templates?(object.protocol)
      urls_list[:duplicate_url] =
        duplicate_protocol_result_template_url(object.protocol, object)
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
