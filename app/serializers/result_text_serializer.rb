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
    custom_auto_link(object.tinymce_render('text'),
                     simple_format: false,
                     tags: %w(img),
                     team: object.result.my_module.team)
  end

  def text
    sanitize_input(object.tinymce_render('text'))
  end

  def icon
    'fa-font'
  end

  def urls
    result = object.result

    return {} if object.destroyed? || !can_manage_result?(scope[:user] || @instance_options[:user], result)

    {
      duplicate_url: duplicate_my_module_result_text_path(result.my_module, result, object),
      delete_url: my_module_result_text_path(result.my_module, result, object),
      update_url: my_module_result_text_path(result.my_module, result, object),
      move_targets_url: move_targets_my_module_result_text_path(result.my_module, result, object),
      move_url: move_my_module_result_text_path(result.my_module, result, object)
    }
  end
end
