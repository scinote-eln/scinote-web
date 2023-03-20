# frozen_string_literal: true

class RepositoryColumnSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include InputSanitizeHelper

  attributes :message

  def message
    if instance_options[:creating]
      I18n.t('libraries.repository_columns.create.success_flash', name: escape_input(object.name))
    elsif instance_options[:editing]
      I18n.t('libraries.repository_columns.update.success_flash', name: escape_input(object.name))
    end
  end
end
