# frozen_string_literal: true

class ResultSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper

  attributes :name, :id, :urls, :updated_at, :created_at_formatted, :updated_at_formatted, :user, :my_module_id

  def updated_at
    object.updated_at.to_i
  end

  def user
    {
      avatar: object.user&.avatar_url(:icon_small),
      name: object.user&.full_name
    }
  end

  def created_at_formatted
    I18n.l(object.created_at, format: :full)
  end

  def updated_at_formatted
    I18n.l(object.updated_at, format: :full)
  end

  def urls
    {
      elements_url: elements_my_module_result_path(object.my_module, object),
      attachments_url: assets_my_module_result_path(object.my_module, object)
    }
  end
end
