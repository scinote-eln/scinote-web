# frozen_string_literal: true

class ChecklistSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :id, :name, :urls, :icon, :sa_name
  has_many :checklist_items, serializer: ChecklistItemSerializer

  def icon
    'fa-list-ul'
  end

  def sa_name
    @user = scope[:user] || @instance_options[:user]
    custom_auto_link(object.name,
                     simple_format: false,
                     tags: %w(img),
                     team: object.step.protocol.team)
  end

  def urls
    return {} if object.destroyed? || !can_manage_step?(scope[:user] || @instance_options[:user], object.step)

    {
      delete_url: step_checklist_path(object.step, object),
      update_url: step_checklist_path(object.step, object),
      reorder_url: reorder_step_checklist_checklist_items_path(object.step, object),
      create_item_url: step_checklist_checklist_items_path(object.step, object)
    }
  end
end
