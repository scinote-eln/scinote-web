# frozen_string_literal: true

class FormResponseSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :created_at, :form_id

  has_many :form_field_values do
    object.form_field_values.latest
  end

  def submitted_by_full_name
    object.submitted_by.full_name
  end
end
