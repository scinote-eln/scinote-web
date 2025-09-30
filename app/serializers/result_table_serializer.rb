# frozen_string_literal: true

class ResultTableSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers

  attributes :name, :contents, :urls, :icon, :metadata, :parent_type

  def contents
    object.contents_utf_8
  end

  def icon
    'sn-icon-tables'
  end

  def parent_type
    :result
  end

  def urls
    return if object.destroyed?

    object.reload unless object.result_or_template
    user = scope[:user] || @instance_options[:user]

    case object.result_or_template
    when Result
      return {} unless can_manage_result?(user, object.result)

      my_module = object.result.my_module
      result = object.result
      {
        duplicate_url: duplicate_my_module_result_table_path(my_module, result, object),
        delete_url: my_module_result_table_path(my_module, result, object),
        update_url: my_module_result_table_path(my_module, result, object),
        move_targets_url: move_targets_my_module_result_table_path(my_module, result, object),
        move_url: move_my_module_result_table_path(my_module, result, object)
      }
    when ResultTemplate
      return {} unless can_manage_result_template?(user, object.result_template)

      protocol = object.result_template.protocol
      template = object.result_template
      {
        duplicate_url: duplicate_protocol_result_template_table_path(protocol, template, object),
        delete_url: protocol_result_template_table_path(protocol, template, object),
        update_url: protocol_result_template_table_path(protocol, template, object),
        move_targets_url: move_targets_protocol_result_template_table_path(protocol, template, object),
        move_url: move_protocol_result_template_table_path(protocol, template, object)
      }
    end
  end
end
