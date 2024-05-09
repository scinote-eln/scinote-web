# frozen_string_literal: true

class QuickSearchSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include BreadcrumbsHelper

  attributes :updated_at, :archived, :breadcrumbs, :code

  def archived
    @object.archived?
  rescue StandardError
    false
  end

  def code
    @object.respond_to?(:code) ? @object.code : @object.id
  end

  def updated_at
    I18n.l(@object.updated_at, format: :full_date)
  end

  def breadcrumbs
    generate_breadcrumbs(@object, [])
  end
end
