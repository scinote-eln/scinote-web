# frozen_string_literal: true

module Experiments
  class TableViewService
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::DateHelper
    include CommentHelper

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
    ).freeze

    PRELOAD = %i(
      results
      my_module_status
    ).freeze

    def initialize(my_modules, user, _page = 1)
      @user = user
      @my_modules = my_modules
      @page = 1
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
        count: my_module.results.length,
        url: results_my_module_path(my_module)
      }
    end

    def status_presenter(my_module)
      {
        name: my_module.my_module_status.name,
        color: my_module.my_module_status.color
      }
    end

    def assigned_presenter(my_module); end

    def tags_presenter(my_module); end

    def comments_presenter(my_module)
      {
        id: my_module.id,
        count: my_module.comments.count,
        count_unseen: count_unseen_comments(my_module, @user)
      }
    end
  end
end
