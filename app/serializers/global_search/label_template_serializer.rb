# frozen_string_literal: true

module GlobalSearch
  class LabelTemplateSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :id, :name, :format, :created_at, :updated_at, :created_by, :team, :url

    def team
      {
        name: object.team.name,
        url: label_templates_path(team: object.team)
      }
    end

    def created_by
      {
        name: object.type == 'FluicsLabelTemplate' ? object.created_by_user : object.created_by&.name,
        avatar_url: object.created_by ? avatar_path(object.created_by, :icon_small) : nil
      }
    end

    def format
      object.label_format
    end

    def created_at
      I18n.l(object.created_at, format: :full_date)
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date)
    end

    def url
      label_template_path(object)
    end
  end
end
