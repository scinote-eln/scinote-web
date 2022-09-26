# frozen_string_literal: true

class LabelPrinterSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :description, :type_of, :language_type, :status

  def urls
    {
    }
  end
end
