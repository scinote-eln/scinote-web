# frozen_string_literal: true

module Lists
  class ProtocolRepositoryRowSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include Canaid::Helpers::PermissionsHelper

    attributes :name, :row_code, :repository_name, :row_url, :repository_url, :archived

    def name
      object.repository_row&.name if check_read_permissions
    end

    def repository_name
      repository&.name if check_read_permissions
    end

    def row_code
      object.repository_row&.code
    end

    def archived
      repository&.archived || object.repository_row&.archived
    end

    def row_url
      repository_repository_row_path(repository, object.repository_row) if check_read_permissions
    end

    def repository_url
      repository_path(repository) if check_read_permissions
    end

    private

    def check_read_permissions
      if object.repository_row
        @can_read_repository ||= can_read_repository?(repository)
      else
        false
      end
    end

    def repository
      @repository ||= object.repository_row&.repository
    end
  end
end
