# frozen_string_literal: true

class RepositoryColumnSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :name, :message, :edit_html_url, :update_url, :destroy_html_url

  def message
    if instance_options[:creating]
      I18n.t('libraries.repository_columns.create.success_flash', name: object.name)
    elsif instance_options[:editing]
      I18n.t('libraries.repository_columns.update.success_flash', name: object.name)
    end
  end

  def edit_html_url
    edit_repository_repository_column_path(object.repository, object)
  end

  def update_url
    repository_repository_columns_text_column_path(object.repository, object)
  end

  def destroy_html_url
    repository_columns_destroy_html_path(object.repository, object)
  end
end
