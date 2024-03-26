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
      comments
      due_date_formatted
      permissions
      default_public_user_role_id
      team
    )

    def attributes(_options = {})
      ATTRIBUTES.index_with do |attribute|
        __send__(attribute)
      end
    end

    delegate :name, to: :object

    delegate :provisioning_status, to: :object

    def default_public_user_role_id
      object.experiment.project.default_public_user_role_id
    end

    delegate :code, to: :object

    def permissions
      {
        manage_designated_users: can_manage_my_module_designated_users?(object),
        manage_tags: can_manage_my_module_tags?(object),
        create_comments: can_create_my_module_comments?(object)

      }
    end

    def urls
      user = scope[:user] || @instance_options[:user]

      urls_list = {
        show: protocols_my_module_path(object, view_mode: archived ? 'archived' : 'active'),
        results: my_module_results_path(object),
        assign_tags: my_module_my_module_tags_path(object),
        assigned_tags: assigned_tags_my_module_my_module_tags_path(object),
        users_list: search_my_module_user_my_module_path(object, my_module_id: object.id),
        experiments_to_move: experiments_to_move_experiment_path(object.experiment),
        move: move_modules_experiment_path(object.experiment),
        update: my_module_path(object),
        show_access: access_permissions_my_module_path(object),
        provisioning_status: provisioning_status_my_module_url(object)
      }

      if can_manage_project_users?(object.experiment.project)
        urls_list[:update_access] = access_permissions_my_module_path(object)
      end

      if can_update_my_module_due_date?(object)
        urls_list[:update_due_date] = my_module_path(object, user, format: :json)
      end

      urls_list
    end

    def due_date
      I18n.l(object.due_date, format: :default) if object.due_date
    end

    def due_date_formatted
      I18n.l(object.due_date, format: :full_date) if object.due_date
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
        {
          id: tag.id,
          name: tag.name,
          color: tag.color
        }
      end
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
  end
end
