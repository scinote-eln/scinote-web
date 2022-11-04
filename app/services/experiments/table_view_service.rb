# frozen_string_literal: true

module Experiments
  class TableViewService
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::DateHelper
    include CommentHelper
    include ProjectsHelper
    include InputSanitizeHelper
    include Canaid::Helpers::PermissionsHelper

    COLUMNS = %i(
      task_name
      id
      due_date
      age
      results
      status
      assigned
      tags
      comments
    )

    PRELOAD = {
      results: {},
      my_module_status: {},
      tags: {},
      task_comments: {},
      user_assignments: :user
    }

    def initialize(my_modules, user, page = 1)
      @my_modules = my_modules
      @page = page
      @user = user
    end

    def call
      result = {}
      @my_modules.includes(PRELOAD).each do |my_module|
        prepared_my_module = []
        COLUMNS.each do |col|
          column_data = {
            column_type: col
          }
          column_data[:data] = __send__("#{col}_presenter", my_module)
          prepared_my_module.push(column_data)
        end

        result[my_module.id] = prepared_my_module
      end
      result
    end

    private

    def task_name_presenter(my_module)
      {
        name: my_module.name,
        url: protocols_my_module_path(my_module)
      }
    end

    def id_presenter(my_module)
      my_module.id
    end

    def due_date_presenter(my_module)
      if my_module.due_date
        I18n.l(my_module.due_date, format: :full_date)
      else
        ''
      end
    end

    def age_presenter(my_module)
      time_ago_in_words(my_module.created_at)
    end

    def results_presenter(my_module)
      {
        count: my_module.results.active.length,
        url: results_my_module_path(my_module)
      }
    end

    def status_presenter(my_module)
      {
        name: my_module.my_module_status.name,
        color: my_module.my_module_status.color
      }
    end

    def assigned_presenter(my_module)
      user_assignments = my_module.user_assignments
      result = {
        count: user_assignments.length,
        users: []
      }
      user_assignments[0..3].each do |ua|
        result[:users].push({
                              image_url: avatar_path(ua.user, :icon_small),
                              title: user_name_with_role(ua)
                            })
      end

      result[:more_users_title] = user_names_with_roles(user_assignments[4..].to_a) if user_assignments.length > 3

      if can_manage_my_module_users?(@user, my_module)
        result[:manage_url] = index_old_my_module_user_my_modules_url(my_module_id: my_module.id, format: :json)
      end

      result
    end

    def tags_presenter(my_module)
      {
        my_module_id: my_module.id,
        tags: my_module.tags.length,
        edit_url: my_module_tags_edit_path(my_module, format: :json)
      }
    end

    def comments_presenter(my_module)
      {
        id: my_module.id,
        count: my_module.comments.count,
        count_unseen: count_unseen_comments(my_module, @user)
      }
    end
  end
end
