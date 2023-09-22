# frozen_string_literal: true

class ChecklistItemSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :text, :checked, :position, :urls, :sa_text, :with_paragraphs

  def with_paragraphs
    object.text.include?("\n")
  end

  def sa_text
    @user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.text,
                     simple_format: false,
                     tags: %w(img),
                     team: object.checklist.step.protocol.team)
  end

  def urls
    urls_list = {}
    return urls_list if object.destroyed? || !object.persisted?

    step = object.checklist.step
    my_module = object.checklist.step.protocol.my_module

    if can_manage_step?(scope[:user] || @instance_options[:user], step)
      urls_list[:update_url] = step_checklist_checklist_item_path(step, object.checklist, object)
      urls_list[:delete_url] = step_checklist_checklist_item_path(step, object.checklist, object)
    end

    return urls_list unless my_module

    if !object.checked && can_check_my_module_steps?(scope[:user] || @instance_options[:user], my_module) ||
       object.checked && can_uncheck_my_module_steps?(scope[:user] || @instance_options[:user], my_module)
      urls_list[:toggle_url] =
        toggle_step_checklist_checklist_item_path(step, object.checklist, object)
    end

    urls_list
  end
end
