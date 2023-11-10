module Lists
  class ProjectAndFolderSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers

    attributes :name, :code, :created_at, :archived_on, :users, :hidden, :urls, :folder

    def folder
      !project?
    end

    def code
      object.code if project?
    end

    def created_at
      I18n.l(object.created_at, format: :full) if project?
    end

    def archived_on
      I18n.l(object.archived_on, format: :full) if project? && object.archived_on
    end

    def hidden
      object.hidden? if project?
    end

    def users
      if project?
        object.user_assignments.map do |ua|
          {
            avatar: avatar_path(ua.user, :icon_small),
            full_name: ua.user_name_with_role
          }
        end
      end
    end

    def urls
      {
        show: project? ? project_path(object) : project_folder_path(object),
        actions: actions_toolbar_projects_path(items: [{id: object.id, type: project? ? 'projects' : 'project_folders'}].to_json)
      }
    end

    private

    def project?
      object.class == Project
    end
  end
end
