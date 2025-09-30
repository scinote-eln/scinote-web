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
    team = if object.result_or_template.is_a?(Result)
             object.result_or_template.my_module.team
           else
             object.result_or_template.protocol.team
           end
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

    case object.result_or_template
    when Result
      return {} unless can_manage_result?(user, object.result)

      result = object.result
      object.result.my_module
      {
        duplicate_url: duplicate_my_module_result_text_path(result.my_module, result, object),
        delete_url: my_module_result_text_path(result.my_module, result, object),
        update_url: my_module_result_text_path(result.my_module, result, object),
        move_targets_url: move_targets_my_module_result_text_path(result.my_module, result, object),
        move_url: move_my_module_result_text_path(result.my_module, result, object)
      }
    when ResultTemplate
      return {} unless can_manage_result_template?(user, object.result_template)

      protcol = object.result_template.protocol
      template = object.result_template
      {
        duplicate_url: duplicate_protocol_result_template_text_path(protcol, template, object),
        delete_url: protocol_result_template_path(protcol, template, object),
        update_url: protocol_result_template_path(protcol, template, object),
        move_targets_url: move_targets_protocol_result_template_text_path(protcol, template, object),
        move_url: move_protocol_result_template_text_path(protcol, template, object)
      }
    end
  end
end
