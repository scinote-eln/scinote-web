# frozen_string_literal: true

class RepositoryColumnSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :message

  def message
    if instance_options[:creating]
      I18n.t('libraries.repository_columns.create.success_flash', name: object.name)
    elsif instance_options[:editing]
      I18n.t('libraries.repository_columns.update.success_flash', name: object.name)
    end
  end
end
