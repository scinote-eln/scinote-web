# frozen_string_literal: true

class ProtocolDraftSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :previous_number, :modified_on, :modified_by, :comment, :urls

  def previous_number
    object.previous_version&.version_number
  end

  def modified_on
    I18n.l(object.updated_at, format: :full_date) if object.updated_at
  end

  def modified_by
    object.last_modified_by&.full_name
  end

  def comment
    object.version_comment
  end

  def urls
    current_user = scope
    urls_list = {
      show: protocol_path(object)
    }

    urls_list[:publish] = publish_protocol_path(object) if can_publish_protocol_in_repository?(current_user, object)
    if can_delete_protocol_draft_in_repository?(current_user, object)
      urls_list[:destroy] = destroy_draft_protocol_path(object)
    end

    if can_manage_protocol_draft_in_repository?(current_user, object) &&
       can_publish_protocol_in_repository?(current_user, object)
      urls_list[:comment] = update_version_comment_protocol_path(object)
    end

    urls_list
  end
end
