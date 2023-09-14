# frozen_string_literal: true

class StepSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include CommentHelper
  include InputSanitizeHelper

  attributes :name, :position, :completed, :attachments_manageble, :urls, :assets_view_mode,
             :marvinjs_enabled, :marvinjs_context, :created_by, :created_at, :assets_order,
             :wopi_enabled, :wopi_context, :comments_count, :unseen_comments, :storage_limit,
             :type, :open_vector_editor_context

  def marvinjs_enabled
    MarvinJsService.enabled?
  end

  def type
    'Step'
  end

  def marvinjs_context
    if marvinjs_enabled
      {
        marvin_js_asset_url: marvin_js_assets_path,
        icon: image_path('icon_small/marvinjs.svg')
      }
    end
  end

  def open_vector_editor_context
    if can_manage_step?(object)
      {
        new_sequence_asset_url: new_gene_sequence_asset_url(parent_type: 'Step', parent_id: object.id),
        icon: image_path('icon_small/sequence-editor.svg')
      }
    end
  end

  def comments_count
    object.comments.count
  end

  def unseen_comments
    has_unseen_comments?(object)
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

  def storage_limit
    nil
  end

  def assets_order
    object.current_view_state(@instance_options[:user]).state.dig('assets', 'sort') unless object.destroyed?
  end

  def attachments_manageble
    can_manage_step?(object)
  end

  def urls
    urls_list = {
      elements_url: elements_step_path(object),
      attachments_url: attachments_step_path(object)
    }

    if object.my_module && can_complete_my_module_steps?(object.my_module)
      urls_list[:state_url] = toggle_step_state_step_path(object)
    end

    if can_manage_protocol_in_module?(object.protocol) || can_manage_protocol_draft_in_repository?(object.protocol)
      urls_list[:duplicate_step_url] = duplicate_step_path(object)
    end

    if can_manage_step?(object)
      urls_list.merge!({
        delete_url: step_path(object),
        update_url: step_path(object),
        create_table_url: step_tables_path(object),
        create_text_url: step_texts_path(object),
        create_checklist_url: step_checklists_path(object),
        update_asset_view_mode_url: update_asset_view_mode_step_path(object),
        update_view_state_url: update_view_state_step_path(object),
        direct_upload_url: rails_direct_uploads_url,
        upload_attachment_url: upload_attachment_step_path(object),
        reorder_elements_url: reorder_step_step_orderable_elements_path(step_id: object.id)
      })
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
