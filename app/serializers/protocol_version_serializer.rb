# frozen_string_literal: true

class ProtocolVersionSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :number, :published_on, :published_by, :comment, :urls

  def urls
    current_user = scope
    urls_list = {
      show: protocol_path(object)
    }
    if can_save_protocol_version_as_draft?(current_user, object)
      urls_list[:save_as_draft] = save_as_draft_protocol_path(object)
    end

    urls_list
  end

  def number
    object.version_number
  end

  def published_on
    I18n.l(object.published_on, format: :full_date) if object.published_on
  end

  def published_by
    object.published_by&.full_name
  end

  def comment
    object.version_comment
  end
end
