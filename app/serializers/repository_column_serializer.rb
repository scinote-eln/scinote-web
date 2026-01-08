# frozen_string_literal: true

class RepositoryColumnSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include InputSanitizeHelper

  attributes :message, :name, :data_type, :metadata, :column_items

  def column_items
    if object.data_type == 'RepositoryListValue'
      object.repository_list_items.map do |item|
        { id: item.id, label: item.data }
      end
    elsif object.data_type == 'RepositoryChecklistValue'
      object.repository_checklist_items.map do |item|
        { id: item.id, label: item.data }
      end
    end
  end

  def message
    if instance_options[:creating]
      I18n.t('libraries.repository_columns.create.success_flash', name: escape_input(object.name))
    elsif instance_options[:editing]
      I18n.t('libraries.repository_columns.update.success_flash', name: escape_input(object.name))
    end
  end
end
