# frozen_string_literal: true

class FormSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :id, :name, :archived, :published_on, :published_by, :updated_at, :description, :urls, :can_manage_form_draft

  has_many :form_fields,
           key: :form_fields,
           serializer: FormFieldSerializer

  def published_by
    object.published_by&.full_name
  end

  def archived
    object.archived?
  end

  def published_on
    I18n.l(object.published_on, format: :full) if object.published_on
  end

  def updated_at
    I18n.l(object.updated_at, format: :full) if object.updated_at
  end

  def can_manage_form_draft
    user = scope[:user] || @instance_options[:user]
    can_manage_form_draft?(user, object)
  end

  def urls
    user = scope[:user] || @instance_options[:user]
    list = { show: form_path(object) }

    if can_manage_form_draft?(user, object)
      list[:create_field] = form_form_fields_path(object)
      list[:reorder_fields] = reorder_form_form_fields_path(object)
    end

    list[:publish] = publish_form_path(object) if can_publish_form?(user, object)
    list[:unpublish] = unpublish_form_path(object) if can_unpublish_form?(user, object)

    list
  end
end
