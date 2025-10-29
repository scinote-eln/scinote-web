# frozen_string_literal: true

class ResultTextSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :text, :urls, :text_view, :icon, :placeholder, :name, :parent_type

  def updated_at
    object.updated_at.to_i
  end

  def placeholder
    I18n.t('my_modules.results.text.placeholder')
  end

  def parent_type
    :result
  end

  def text_view
    @user = scope[:user]
    team = object.result.parent.team
    custom_auto_link(object.tinymce_render('text'),
                     simple_format: false,
                     tags: %w(img),
                     team: team)
  end

  def text
    sanitize_input(object.tinymce_render('text'))
  end

  def icon
    'sn-icon-result-text'
  end

  def urls
    return {} if object.destroyed?

    user = scope[:user] || @instance_options[:user]

    return {} unless can_manage_result?(user, object.result)

    result = object.result
    {
      duplicate_url: duplicate_result_text_path(result, object),
      delete_url: result_text_path(result, object),
      update_url: result_text_path(result, object),
      move_targets_url: move_targets_result_text_path(result, object),
      move_url: move_result_text_path(result, object)
    }
  end
end
