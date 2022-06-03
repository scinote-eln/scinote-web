# frozen_string_literal: true

class ProtocolSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :name, :id, :urls, :description, :description_view, :updated_at, :in_repository

  def updated_at
    object.updated_at.to_i
  end

  def description_view
    @user = @instance_options[:user]
    custom_auto_link(object.tinymce_render('description'),
                     simple_format: false,
                     tags: %w(img),
                     team: object.team)
  end

  def description
    sanitize_input(object.tinymce_render('description'))
  end

  def urls
    {
      load_from_repo_url: load_from_repo_url,
      save_to_repo_url: save_to_repo_url,
      export_url: export_url,
      import_url: import_url,
      steps_url: steps_url,
      reorder_steps_url: reorder_steps_url,
      add_step_url: add_step_url,
      update_protocol_url: update_protocol_url
    }
  end

  def in_repository
    !object.in_module?
  end

  private

  def load_from_repo_url
    return unless can_manage_protocol_in_module?(object)

    load_from_repository_modal_protocol_path(object, format: :json)
  end

  def save_to_repo_url
    return unless can_read_protocol_in_module?(object) && can_create_protocols_in_repository?(object.team)

    copy_to_repository_modal_protocol_path(object, format: :json)
  end

  def import_url
    return unless can_manage_protocol_in_module?(object)

    load_from_file_protocol_path(object, format: :json)
  end

  def export_url
    return unless can_read_protocol_in_module?(object)

    export_protocols_path(protocol_ids: object.id, my_module_id: object.my_module.id)
  end

  def steps_url
    return unless can_read_protocol_in_module?(object) || can_read_protocol_in_repository?(object)

    steps_path(protocol_id: object.id)
  end

  def reorder_steps_url
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_in_repository?(object)

    reorder_protocol_steps_url(protocol_id: object.id)
  end

  def add_step_url
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_in_repository?(object)

    protocol_steps_path(protocol_id: object.id)
  end

  def update_protocol_url
    if in_repository && can_manage_protocol_in_repository?(object)
      protocol_path(@protocol)
    elsif can_manage_protocol_in_module?(object)
      protocol_my_module_path(object.my_module)
    end
  end
end
