# frozen_string_literal: true

module Lists
  class RepositorySerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers
    include ShareableSerializer

    attributes :name, :code, :nr_of_rows, :team, :created_at, :created_by, :archived_on, :archived_by, :urls

    def nr_of_rows
      object[:repository_rows_count]
    end

    def team
      object[:team_name]
    end

    def created_at
      I18n.l(object.created_at, format: :full)
    end

    def created_by
      object[:created_by_user]
    end

    def archived_on
      I18n.l(object.archived_on, format: :full) if object.archived_on
    end

    def archived_by
      object[:archived_by_user]
    end

    def urls
      {
        show: repository_path(object),
        update: team_repository_path(current_user.current_team, id: object, format: :json),
        duplicate: team_repository_copy_path(current_user.current_team, repository_id: object, format: :json),
        shareable_teams: shareable_teams_team_shared_objects_path(
          current_user.current_team, object_id: object.id, object_type: 'Repository'
        ),
        share: team_shared_objects_path(current_user.current_team, object_id: object.id, object_type: 'Repository')
      }
    end
  end
end
