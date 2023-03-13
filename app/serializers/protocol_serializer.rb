# frozen_string_literal: true

class ProtocolSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper

  attributes :name, :id, :urls, :description, :description_view, :updated_at, :in_repository,
             :created_at_formatted, :updated_at_formatted, :added_by, :authors, :keywords, :version, :code,
             :published, :version_comment, :archived, :linked

  def updated_at
    object.updated_at.to_i
  end

  def version
    object.in_repository_draft? ? I18n.t('protocols.draft') : object.version_number
  end

  def published
    object.in_repository_published?
  end

  def added_by
    {
      avatar: object.added_by&.avatar_url(:icon_small),
      name: object.added_by&.full_name
    }
  end

  def created_at_formatted
    I18n.l(object.created_at, format: :full)
  end

  def updated_at_formatted
    I18n.l(object.updated_at, format: :full)
  end

  def keywords
    object.protocol_keywords.map { |i| { label: i.name, value: i.name } }
  end

  def code
    object&.parent&.code || object.code
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
      unlink_url: unlink_url,
      revert_protocol_url: revert_protocol_url,
      update_protocol_url: update_protocol_url,
      steps_url: steps_url,
      reorder_steps_url: reorder_steps_url,
      add_step_url: add_step_url,
      update_protocol_name_url: update_protocol_name_url,
      update_protocol_description_url: update_protocol_description_url,
      update_protocol_authors_url: update_protocol_authors_url,
      update_protocol_keywords_url: update_protocol_keywords_url,
      delete_steps_url: delete_steps_url,
      publish_url: publish_url,
      save_as_draft_url: save_as_draft_url,
      versions_modal_url: versions_modal_url,
      print_protocol_url: print_protocol_url
    }
  end

  def in_repository
    !object.in_module?
  end

  def linked
    object.linked?
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

  def export_url
    return unless can_read_protocol_in_module?(object)

    export_protocols_path(protocol_ids: object.id, my_module_id: object.my_module.id)
  end

  def steps_url
    return unless can_read_protocol_in_module?(object) || can_read_protocol_in_repository?(object)

    steps_path(protocol_id: object.id)
  end

  def versions_modal_url
    return unless can_read_protocol_in_repository?(object)

    versions_modal_protocol_path(object.parent || object)
  end

  def print_protocol_url
    return unless can_read_protocol_in_repository?(object)

    print_protocol_path(object)
  end

  def reorder_steps_url
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_in_repository?(object)

    reorder_protocol_steps_url(protocol_id: object.id)
  end

  def add_step_url
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_in_repository?(object)

    protocol_steps_path(protocol_id: object.id)
  end

  def unlink_url
    return unless can_manage_protocol_in_module?(object) && object.linked?

    unlink_modal_protocol_path(object, format: :json)
  end

  def revert_protocol_url
    return unless can_read_protocol_in_module?(object) && object.linked? && object.newer_than_parent?

    revert_modal_protocol_path(object, format: :json)
  end

  def update_protocol_url
    return unless can_read_protocol_in_module?(object) && object.linked? && object.parent_newer?

    update_from_parent_modal_protocol_path(object, format: :json)
  end

  def update_protocol_name_url
    if in_repository && can_manage_protocol_in_repository?(object)
      name_protocol_path(object)
    elsif can_manage_protocol_in_module?(object)
      protocol_my_module_path(object.my_module)
    end
  end

  def update_protocol_description_url
    if in_repository && can_manage_protocol_in_repository?(object)
      description_protocol_path(object)
    elsif can_manage_protocol_in_module?(object)
      protocol_my_module_path(object.my_module)
    end
  end

  def update_protocol_authors_url
    authors_protocol_path(object) if in_repository && can_manage_protocol_in_repository?(object)
  end

  def update_protocol_keywords_url
    keywords_protocol_path(object) if in_repository && can_manage_protocol_in_repository?(object)
  end

  def delete_steps_url
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_in_repository?(object)

    delete_steps_protocol_path(object)
  end

  def publish_url
    return unless can_publish_protocol_in_repository?(object)

    publish_protocol_path(object)
  end

  def save_as_draft_url
    return unless can_save_protocol_as_draft_in_repository?(object)

    save_as_draft_protocol_path(object)
  end
end
