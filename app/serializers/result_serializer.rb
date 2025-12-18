# frozen_string_literal: true

class ResultSerializer < ResultBaseSerializer
  attributes :my_module_id, :archived, :comments_count

  def collapsed
    result_states = current_user.settings.fetch('result_states', {})
    result_states[object.id.to_s] == true
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

  def comments_count
    object.comments.count
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
                         create_table_url: result_tables_path(object),
                         create_text_url: result_texts_path(object),
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

    if can_manage_result?(object)
      if object.pinned?
        urls_list[:unpin_url] = unpin_my_module_result_path(object.my_module, object)
      else
        urls_list[:pin_url] = pin_my_module_result_path(object.my_module, object)
      end
    end

    urls_list
  end
end
