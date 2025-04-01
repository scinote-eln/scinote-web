# frozen_string_literal: true

class FormFieldValueSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :form_field_id, :type, :value, :submitted_at, :submitted_by_full_name,
             :unit, :not_applicable, :selection, :datetime, :datetime_to

  def submitted_by_full_name
    object.submitted_by.full_name
  end

  def submitted_at
    I18n.l(object.submitted_at, format: :full) if object.submitted_at
  end
end
