# frozen_string_literal: true

module Lists
  class RepositorySerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers

    attributes :name, :code, :nr_of_rows, :shared, :shared_label, :ishared,
               :team, :created_at, :created_by, :archived_on, :archived_by,
               :urls, :shared_read, :shared_write, :shareable_write

    def nr_of_rows
      object[:row_count]
    end

    def shared
      object.shared_with?(current_user.current_team)
    end

    def shared_label
      if object.i_shared?(current_user.current_team)
        I18n.t('libraries.index.shared')
      elsif object.shared_with?(current_user.current_team)
        if object.shared_with_read?(current_user.current_team)
          I18n.t('libraries.index.shared_for_viewing')
        else
          I18n.t('libraries.index.shared_for_editing')
        end
      else
        I18n.t('libraries.index.not_shared')
      end
    end

    def ishared
      object.i_shared?(current_user.current_team)
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

    def shared_read
      object.shared_read?
    end

    def shared_write
      object.shared_write?
    end

    def shareable_write
      object.shareable_write?
    end

    def urls
      {
        show: repository_path(object),
        update: team_repository_path(current_user.current_team, id: object, format: :json),
        shareable_teams: shareable_teams_team_repository_path(current_user.current_team, object),
        duplicate: team_repository_copy_path(current_user.current_team, repository_id: object, format: :json),
        share: team_repository_team_repositories_path(current_user.current_team, object)
      }
    end
  end
end
