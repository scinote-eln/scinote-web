# frozen_string_literal: true

module Lists
  class ProjectAndFolderSerializer < ActiveModel::Serializer
    include Rails.application.routes.url_helpers
    include Canaid::Helpers::PermissionsHelper
    include CommentHelper

    attributes :name, :code, :created_at, :archived_on, :users, :urls, :folder, :hidden,
               :folder_info, :default_public_user_role_id, :team, :top_level_assignable,
               :comments, :updated_at, :permissions

    def team
      object.team.name
    end

    def folder
      !project?
    end

    def top_level_assignable
      project?
    end

    def hidden
      object.hidden? if project?
    end

    def default_public_user_role_id
      object.default_public_user_role_id if project?
    end

    def code
      object.code if project?
    end

    def created_at
      I18n.l(object.created_at, format: :full_date) if project?
    end

    def updated_at
      I18n.l(object.updated_at, format: :full_date) if project?
    end

    def archived_on
      I18n.l(object.archived_on, format: :full) if project? && object.archived_on
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

    def comments
      if project?
        @user = scope[:user] || @instance_options[:user]
        {
          count: object.comments.count,
          count_unseen: count_unseen_comments(object, @user)
        }
      end
    end

    def urls
      urls_list = {
        show: if project?
                experiments_path(project_id: object, view_mode: object.archived ? 'archived' : 'active')
              else
                project_folder_path(object, view_mode: object.archived ? 'archived' : 'active')
              end,
        actions: actions_toolbar_projects_path(items: [{ id: object.id,
                                                         type: project? ? 'projects' : 'project_folders' }].to_json)
      }

      urls_list[:show] = nil if project? && !can_read_project?(object)

      urls_list[:update] = if project?
                             project_path(object)
                           else
                             project_folder_path(object)
                           end

      urls_list[:show_access] = access_permissions_project_path(object)
      if project? && can_manage_project_users?(object)
        urls_list[:update_access] = access_permissions_project_path(object)
        urls_list[:new_access] = new_access_permissions_project_path(id: object.id)
        urls_list[:create_access] = access_permissions_projects_path(id: object.id)
        urls_list[:default_public_user_role_path] =
          update_default_public_user_role_access_permissions_project_path(object)
      end

      urls_list
    end

    def permissions
      {
        create_comments: project? ? can_create_project_comments?(object) : false,
        manage_users_assignments: project? ? can_manage_project_users?(object) : false
      }
    end

    def folder_info
      if folder
        I18n.t('projects.index.folder.description', projects_count: object.projects_count,
folders_count: object.folders_count)
      end
    end

    private

    def project?
      object.instance_of?(Project)
    end
  end
end
