# frozen_string_literal: true

class LabelTemplateSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :name, :description, :language_type, :icon_url, :urls, :content, :type,
             :default, :width_mm, :height_mm, :unit, :density

  def icon_url
    ActionController::Base.helpers.image_path("label_template_icons/#{object.icon}.svg")
  end

  def urls
    return {} unless can_manage_label_templates?(object.team)
    {
      update: label_template_path(object),
      fields: template_tags_label_templates_path(id: object.id)
    }
  end
end
