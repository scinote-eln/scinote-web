# frozen_string_literal: true

module Lists
  class LabelTemplateSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    attributes :name, :language_type, :urls, :type,
               :default, :format, :modified_by, :created_by,
               :created_at, :updated_at, :id, :icon_url, :description

    def icon_url
      ActionController::Base.helpers.image_tag(
        "label_template_icons/#{object.icon}.svg",
        class: 'label-template-icon'
      )
    end

    delegate :modified_by, to: :object

    def format
      object.label_format
    end

    def created_by
      object.created_by_user
    end

    def created_at
      I18n.l(object.created_at, format: :full)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full)
    end

    def urls
      return {} unless can_manage_label_templates?(object.team)

      {
        show: label_template_path(object)
      }
    end
  end
end
