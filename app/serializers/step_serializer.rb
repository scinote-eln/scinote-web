# frozen_string_literal: true

class StepSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include CommentHelper
  include InputSanitizeHelper

  has_many :step_orderable_elements, serializer: StepOrderableElementSerializer
  has_many :assets, serializer: AssetSerializer

  attributes :name, :position, :completed, :attachments_manageble, :urls, :assets_view_mode,
             :marvinjs_enabled, :marvinjs_context, :created_by, :created_at, :assets_order,
             :wopi_enabled, :wopi_context, :comments_count, :unseen_comments, :storage_limit,
             :type, :open_vector_editor_context, :collapsed, :my_module_id, :results, :protocol_id, :skipped_at,
             :archived_by, :archived_on, :archived

  def step_orderable_elements
    return object.all_elements if object.archived?

    view_mode = @instance_options[:view_mode]
    if view_mode == 'archived'
      object.archived_elements
    else
      object.active_elements
    end
  end

  def assets
    return object.assets if object.archived?

    view_mode = @instance_options[:view_mode]
    if view_mode == 'archived'
      object.assets.archived
    else
      object.assets.active
    end
  end

  def collapsed
    step_states = @instance_options[:user].user_settings.find_by(key: 'task_step_states')&.value || {}
    step_states[object.id.to_s] == true
  end

  def marvinjs_enabled
    MarvinJsService.enabled?
  end

  def results
    object.results.map do |result|
      { id: result.id, name: result.name, archived: result.archived? }
    end
  end

  def my_module_id
    object.my_module&.id
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
    @instance_options[:view_mode] == 'archived' ? false : can_manage_step?(object)
  end

  def urls
    view_mode = 'archived' if @instance_options[:view_mode]

    url_list = {
      elements_url: elements_step_path(object, view_mode: view_mode),
      attachments_url: attachments_step_path(object, view_mode: view_mode)
    }

    if object.my_module && (object.skipped_at ? can_unskip_my_module_steps?(object.my_module) : can_skip_my_module_steps?(object.my_module))
      url_list[:skip_url] = toggle_step_skip_state_step_path(object)
    end

    if object.my_module && (object.completed ? can_uncomplete_my_module_steps?(object.my_module) : can_complete_my_module_steps?(object.my_module))
      url_list[:state_url] = toggle_step_state_step_path(object)
    end

    if can_manage_protocol_in_module?(object.protocol) || can_manage_protocol_draft_in_repository?(object.protocol)
      url_list[:duplicate_step_url] = duplicate_step_path(object)
    end

    url_list[:archive_url] = archive_step_path(object) if can_archive_step?(object)
    url_list[:restore_url] = restore_step_path(object) if can_restore_step?(object)

    url_list[:delete_url] = step_path(object) if can_delete_step?(object)

    if can_manage_step?(object)
      url_list.merge!({
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

      url_list[:create_form_response_url] = step_form_responses_path(object) if Form.forms_enabled?
    end

    url_list
  end

  def created_at
    I18n.l(object.created_at, format: :full)
  end

  def created_by
    object.user.full_name
  end

  def archived_by
    object.archived_by.presence&.full_name
  end

  def archived_on
    I18n.l(object.archived_on, format: :full) if object.archived_on.present?
  end
end
