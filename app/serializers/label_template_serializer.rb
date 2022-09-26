# frozen_string_literal: true

class LabelTemplateSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :description, :language_type, :icon_url, :urls, :content, :type

  def icon_url
    ActionController::Base.helpers.image_path("label_template_icons/#{object.icon}.svg")
  end

  def urls
    {
      update: label_template_path(object),
      fields: template_tags_label_templates_path
    }
  end
end
