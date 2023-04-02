# frozen_string_literal: true

class LabelPrinterSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  attributes :name, :display_name, :description, :type_of, :language_type, :status

  def urls
    {
    }
  end

  def display_name
    object.description.present? ? escape_input("#{object.name} • #{object.description}") : escape_input(object.name)
  end

  def status
    object.status.dasherize
  end
end
