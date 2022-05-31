# frozen_string_literal: true

class StepSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include CommentHelper

  attributes :name, :position, :completed, :urls, :assets_view_mode, :assets_order,
             :marvinjs_enabled, :marvinjs_context, :wopi_enabled, :wopi_context, :comments_count, :unseen_comments,
             :storage_limit

  def marvinjs_enabled
    MarvinJsService.enabled?
  end

  def marvinjs_context
    if marvinjs_enabled
      {
        marvin_js_asset_url: marvin_js_assets_path,
        icon: image_path('icon_small/marvinjs.svg')
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
    object.current_view_state(@instance_options[:user]).state.dig('assets', 'sort')
  end

  def urls
    {
      delete_url: step_path(object),
      state_url: toggle_step_state_step_path(object),
      update_url: step_path(object),
      elements_url: elements_step_path(object),
      attachments_url: attachments_step_path(object),
      create_table_url: step_tables_path(object),
      create_text_url: step_texts_path(object),
      create_checklist_url: step_checklists_path(object),
      update_asset_view_mode_url: update_asset_view_mode_step_path(object),
      update_view_state_step_url: update_view_state_step_path(object),
      direct_upload_url: rails_direct_uploads_url,
      upload_attachment_url: upload_attachment_step_path(object),
      reorder_elements_url: reorder_step_step_orderable_elements_path(step_id: object.id)
    }
  end
end
