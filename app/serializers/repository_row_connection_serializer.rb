# frozen_string_literal: true

class RepositoryRowConnectionSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  include Canaid::Helpers::PermissionsHelper

  attributes :id, :code, :name, :path, :repository_name, :repository_path, :can_connect_rows, :unlink_path

  def id
    connected_row.id
  end

  def code
    connected_row.code
  end

  def name
    readable_repository? ? connected_row.name_with_label : I18n.t('repositories.item_card.relationships.private_item_name')
  end

  def path
    repository_repository_row_path(connected_row.repository, connected_row) if readable_repository?
  end

  def repository_name
    connected_row.repository.name_with_label if readable_repository?
  end

  def repository_path
    Rails.application.routes.url_helpers.repository_path(connected_row.repository) if readable_repository?
  end

  def can_connect_rows
    return nil unless live_repository?

    can_connect_repository_rows?(connected_row.repository)
  end

  def unlink_path
    repository_repository_row_repository_row_connection_path(connected_row.repository, connected_row, object)
  end

  private

  def connected_row
    @connected_row ||= object.parent?(instance_options[:repository_row]) ? object.child : object.parent
  end

  def readable_repository?
    @can_read_repository ||= can_read_repository?(connected_row.repository)
  end

  def live_repository?
    connected_row.repository.is_a?(Repository) && !connected_row.repository.is_a?(SoftLockedRepository)
  end
end
