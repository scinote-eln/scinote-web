# frozen_string_literal: true

class ProtocolSerializer < ActiveModel::Serializer
  include Canaid::Helpers::PermissionsHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  include InputSanitizeHelper

  attributes :name, :id, :urls, :description, :description_view, :updated_at, :in_repository,
             :created_at_formatted, :updated_at_formatted, :added_by, :authors, :keywords, :version,
             :code, :published, :version_comment, :archived, :linked, :has_draft,
             :published_on_formatted, :published_by, :created_from_version, :assignable_my_module_id, :assignable_my_module_name

  def updated_at
    object.updated_at.to_i
  end

  def version
    object.version_number
  end

  def created_from_version
    object.previous_version&.version_number
  end

  def published
    object.in_repository_published?
  end

  def published_on_formatted
    return if object.published_on.blank?

    I18n.l(object.published_on, format: :full)
  end

  def published_by
    {
      avatar: object.published_by&.avatar_url(:icon_small),
      name: object.published_by&.full_name
    }
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
    object.protocol_keywords.map { |i| { label: escape_input(i.name), value: escape_input(i.name) } }
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
      version_comment_url: version_comment_url,
      print_protocol_url: print_protocol_url,
      versions_modal: versions_modal_protocol_path(object.parent || object),
      redirect_to_protocols: protocols_path
    }
  end

  def in_repository
    !object.in_module?
  end

  # rubocop:disable Naming/PredicateName
  def has_draft
    return false unless object.in_repository_published?

    (object.parent || object).draft.present?
  end
  # rubocop:enable Naming/PredicateName

  def linked
    object.linked?
  end

  def assignable_my_module_id
    return if in_repository

    object.my_module&.id
  end

  def assignable_my_module_name
    return if in_repository

    object.my_module&.name
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
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_draft_in_repository?(object)

    reorder_protocol_steps_url(protocol_id: object.id)
  end

  def add_step_url
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_draft_in_repository?(object)

    protocol_steps_path(protocol_id: object.id)
  end

  def unlink_url
    return unless can_manage_protocol_in_module?(object) && object.linked?

    unlink_modal_protocol_path(object, format: :json)
  end

  def revert_protocol_url
    return unless can_manage_protocol_in_module?(object) && object.linked? &&
                  object.parent.active? && object.newer_than_parent? &&
                  can_read_protocol_in_repository?(object.parent)

    revert_modal_protocol_path(object, format: :json)
  end

  def update_protocol_url
    return unless can_manage_protocol_in_module?(object) && object.linked? &&
                  object.parent.active? && object.parent_newer? &&
                  can_read_protocol_in_repository?(object.parent)

    update_from_parent_modal_protocol_path(object, format: :json)
  end

  def update_protocol_name_url
    if in_repository && can_manage_protocol_draft_in_repository?(object)
      name_protocol_path(object)
    elsif can_manage_protocol_in_module?(object)
      protocol_my_module_path(object.my_module)
    end
  end

  def update_protocol_description_url
    if in_repository && can_manage_protocol_draft_in_repository?(object)
      description_protocol_path(object)
    elsif can_manage_protocol_in_module?(object)
      protocol_my_module_path(object.my_module)
    end
  end

  def update_protocol_authors_url
    authors_protocol_path(object) if in_repository && can_manage_protocol_draft_in_repository?(object)
  end

  def update_protocol_keywords_url
    keywords_protocol_path(object) if in_repository && can_manage_protocol_draft_in_repository?(object)
  end

  def delete_steps_url
    return unless can_manage_protocol_in_module?(object) || can_manage_protocol_draft_in_repository?(object)

    delete_steps_protocol_path(object)
  end

  def publish_url
    return unless can_publish_protocol_in_repository?(object)

    publish_protocol_path(object)
  end

  def version_comment_url
    return unless can_publish_protocol_in_repository?(object)

    version_comment_protocol_path(object)
  end

  def save_as_draft_url
    return unless can_save_protocol_version_as_draft?(object)

    save_as_draft_protocol_path(object)
  end
end
