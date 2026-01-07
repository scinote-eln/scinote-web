# frozen_string_literal: true

class ResultBaseSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper

  has_many :result_orderable_elements, serializer: ResultOrderableElementSerializer
  has_many :assets, serializer: AssetSerializer

  attributes :name, :id, :urls, :updated_at, :created_at_formatted, :updated_at_formatted, :user,
             :attachments_manageble, :marvinjs_enabled, :marvinjs_context, :type,
             :wopi_enabled, :wopi_context, :created_at, :created_by, :assets_order,
             :open_vector_editor_context, :assets_view_mode, :storage_limit, :collapsed, :steps

  def marvinjs_enabled
    MarvinJsService.enabled?
  end

  def steps
    object.steps.map do |step|
      { id: step.id, name: step.label }
    end
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

  def created_at
    object.created_at.strftime('%B %d, %Y at %H:%M')
  end

  def created_by
    object.user.full_name
  end
end
