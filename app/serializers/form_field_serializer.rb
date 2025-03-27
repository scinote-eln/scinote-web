# frozen_string_literal: true

class FormFieldSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :name, :description, :updated_at, :type, :required,
             :allow_not_applicable, :uid, :position, :urls, :data

  def type
    object.data['type']
  end

  def urls
    {
      show: form_form_field_path(object.form, object),
      duplicate: duplicate_form_form_field_path(object.form, object)
    }
  end
end
