module Lists
  class MyModuleSerializer < ActiveModel::Serializer
    include Canaid::Helpers::PermissionsHelper
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::DateHelper
    include CommentHelper

    ATTRIBUTES = %i(
      name
      provisioning_status
      code
      urls
      due_date
      due_date_status
      archived
      archived_on
      age
      results
      status
      designated_users
      tags
      tags_html
      comments
      due_date_cell
      start_date_cell
      permissions
      default_public_user_role_id
      team
      favorite
    )

    def attributes(_options = {})
      ATTRIBUTES.index_with do |attribute|
        __send__(attribute)
      end
    end

    delegate :name, to: :object

    delegate :provisioning_status, to: :object

    delegate :favorite, to: :object

    delegate :code, :default_public_user_role_id, to: :object

    def permissions
      {
        manage_designated_users: can_manage_my_module_designated_users?(object),
        create_comments: can_create_my_module_comments?(object),
        assign_tags: can_manage_my_module_tags?(object)
      }
    end

    def urls
      user = scope[:user] || @instance_options[:user]

      urls_list = {
        show: protocols_my_module_path(object, view_mode: archived ? 'archived' : 'active'),
        results: my_module_results_path(object),
        tag_resource: tag_resource_my_module_path(object),
        untag_resource: untag_resource_my_module_path(object),
        tag_resource_with_new_tag: tag_resource_with_new_tag_my_module_path(object),
        users_list: search_my_module_user_my_module_path(object, my_module_id: object.id),
        experiments_to_move: experiments_to_move_experiment_path(object.experiment),
        update: my_module_path(object),
        show_access: access_permissions_my_module_path(object),
        show_user_group_assignments_access: show_user_group_assignments_access_permissions_my_module_path(object),
        provisioning_status: provisioning_status_my_module_url(object),
        favorite: favorite_my_module_url(object),
        unfavorite: unfavorite_my_module_url(object),
        user_roles: user_roles_access_permissions_my_module_path(object),
        user_group_members: users_users_settings_team_user_groups_path(team_id: object.team.id)
      }

      if can_manage_project_users?(object.experiment.project)
        urls_list[:update_access] = access_permissions_my_module_path(object)
      end

      urls_list[:update_due_date] = my_module_path(object, user, format: :json) if can_update_my_module_due_date?(object)
      urls_list[:update_start_date] = my_module_path(object, user, format: :json) if can_update_my_module_start_date?(object)

      urls_list
    end

    def due_date
      I18n.l(object.due_date, format: :default) if object.due_date
    end

    def due_date_cell
      {
        value: due_date,
        value_formatted: due_date,
        editable: can_update_my_module_due_date?(object),
        icon: (if object.is_one_day_prior? && !object.completed?
                 'sn-icon sn-icon-alert-warning text-sn-alert-brittlebush'
               elsif object.is_overdue? && !object.completed?
                 'sn-icon sn-icon-alert-warning text-sn-delete-red'
               end)
      }
    end

    def start_date_cell
      {
        value: start_date,
        value_formatted: start_date,
        editable: can_update_my_module_start_date?(object)
      }
    end

    def due_date_status
      if (archived || object.completed?) && object.due_date
        return :ok
      elsif object.is_one_day_prior? && !object.completed?
        return :one_day_prior
      elsif object.is_overdue? && !object.completed?
        return :overdue
      end

      :ok
    end

    def archived
      object.archived_branch?
    end

    def archived_on
      I18n.l(object.archived_on, format: :full_date) if object.archived?
    end

    def age
      time_ago_in_words(object.created_at)
    end

    def results
      (archived ? object.results : object.results.active).length
    end

    def status
      {
        name: object.my_module_status.name,
        color: object.my_module_status.color,
        light_color: object.my_module_status.light_color?
      }
    end

    def designated_users
      object.user_my_modules.map do |user_my_module|
        user = user_my_module.user
        {
          id: user.id,
          name: user.name,
          avatar: avatar_path(user, :icon_small)
        }
      end
    end

    def tags
      object.tags.map do |tag|
        { id: tag.id, name: tag.name, color: tag.color }
      end
    end

    def tags_html
      # legacy canvas support
      return '' unless @instance_options[:controller]

      @instance_options[:controller].render_to_string(
        partial: 'canvas/tags',
        locals: { my_module: object },
        formats: :html
      )
    end

    def comments
      @user = scope[:user] || @instance_options[:user]
      {
        count: object.comments.count,
        count_unseen: count_unseen_comments(object, @user)
      }
    end

    def team
      object.team.name
    end

    private

    def start_date
      I18n.l(object.started_on, format: :default) if object.started_on
    end
  end
end
