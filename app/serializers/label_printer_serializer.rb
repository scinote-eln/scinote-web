# frozen_string_literal: true

class LabelPrinterSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  attributes :name, :display_name, :description, :type_of, :language_type, :status, :display_status

  def urls
    {
    }
  end

  def display_name
    object.description.present? ? sanitize_input("#{object.name} • #{object.description}") : sanitize_input(object.name)
  end

  def status
    object.status.dasherize
  end

  def display_status
    I18n.t("label_printers.fluics.statuses.#{object.status}")
  end
end
