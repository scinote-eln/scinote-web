# frozen_string_literal: true

class ResultTemplateSerializer < ResultBaseSerializer
  attributes :protocol_id

  def collapsed
    result_template_states = current_user.settings.fetch('result_template_states', {})
    result_template_states[object.id.to_s] == true
  end

  def urls
    urls_list = {
      elements_url: elements_protocol_result_template_path(object.protocol, object),
      attachments_url: assets_protocol_result_template_path(object.protocol, object)
    }

    if can_manage_result?(object)
      urls_list.merge!({
                         update_url: protocol_result_template_path(object.protocol, object),
                         create_table_url: result_tables_path(object),
                         create_text_url: result_texts_path(object),
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

    urls_list[:delete_url] = protocol_result_template_path(object.protocol, object) if can_delete_result?(object)
    if can_create_result_templates?(object.protocol)
      urls_list[:duplicate_url] =
        duplicate_protocol_result_template_url(object.protocol, object)
    end

    urls_list
  end

  def open_vector_editor_context
    if can_manage_result?(object)
      {
        new_sequence_asset_url: new_gene_sequence_asset_url(parent_type: 'ResultTemplate', parent_id: object.id),
        icon: image_path('icon_small/sequence-editor.svg')
      }
    end
  end
end
