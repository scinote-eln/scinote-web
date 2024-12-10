# frozen_string_literal: true

class FormSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :name, :published_on, :published_by, :updated_at, :urls

  has_many :form_fields,
           key: :form_fields,
           serializer: FormFieldSerializer,
           order: :position

  def published_by
    object.published_by&.full_name
  end

  def published_on
    I18n.l(object.published_on, format: :full) if object.published_on
  end

  def updated_at
    I18n.l(object.updated_at, format: :full) if object.updated_at
  end

  def urls
    {
      show: form_path(object),
      create_field: form_form_fields_path(object)
    }
  end
end
