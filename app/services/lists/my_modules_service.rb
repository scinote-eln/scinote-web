# frozen_string_literal: true

module Lists
  class MyModulesService < BaseService
    PRELOAD = {
      results: {},
      my_module_status: {},
      tags: {},
      task_comments: { user: :teams },
      user_assignments: :user,
      designated_users: {},
      experiment: { project: :team }
    }

    private

    def fetch_records
      @records = @raw_data.includes(PRELOAD)
                          .with_favorites(@user)
                          .group('my_modules.id')

      view_mode = if @params[:experiment].archived_branch?
                    'archived'
                  else
                    @params[:view_mode] || 'active'
                  end
      @records = @records.archived if view_mode == 'archived' && !@params[:experiment].archived_branch?
      @records = @records.active if view_mode == 'active'
    end

    def filter_records
      if @params[:search].present?
        @records = @records.where_attributes_like(['my_modules.name', MyModule::PREFIXED_ID_SQL], @params[:search])
      end

      @filters.each do |name, value|
        __send__("#{name}_filter", value) if value.present?
      end
    end

    def sortable_columns
      @sortable_columns ||= {
        start_date: 'start_date',
        due_date: 'due_date',
        name: 'name',
        code: 'id',
        archived_on: 'archived_on',
        age: 'age',
        status: 'status',
        designated: 'designated',
        results: 'results',
        tags: 'tags',
        signatures: 'signatures',
        comments: 'comments',
        favorite: 'favorite'
      }
    end

    def select_count_for_sort
      case sortable_columns[order_params[:column].to_sym]
      when 'comments'
        @records = @records.left_joins(:task_comments).select('COUNT(DISTINCT comments.id) AS comment_count')
      when 'designated'
        @records = @records.left_joins(:user_my_modules).select('COUNT(DISTINCT user_my_modules.id) AS designated_count')
      when 'results'
        @records = @records.left_joins(:results).select('COUNT(DISTINCT results.id) AS result_count')
      when 'tags'
        @records = @records.left_joins(:tags).select('COUNT(DISTINCT tags.id) AS tag_count')
      end
    end

    def sort_records
      return unless @params[:order]

      sort = "#{sortable_columns[order_params[:column].to_sym]}_#{sort_direction(order_params)}"
      select_count_for_sort

      case sort
      when 'start_date_ASC'
        @records = @records.order(:started_on, :name)
      when 'start_date_DESC'
        @records = @records.order(started_on: :desc, name: :asc)
      when 'due_date_ASC'
        @records = @records.order(:due_date, :name)
      when 'due_date_DESC'
        @records = @records.order({ due_date: :desc }, :name)
      when 'name_ASC'
        @records = @records.order(:name)
      when 'name_DESC'
        @records = @records.order(name: :desc)
      when 'id_ASC'
        @records = @records.order(:id)
      when 'id_DESC'
        @records = @records.order(id: :desc)
      when 'archived_on_ASC'
        @records = @records.order(archived_on: :asc)
      when 'archived_on_DESC'
        @records = @records.order(archived_on: :desc)
      when 'age_ASC'
        @records = @records.order(created_at: :desc)
      when 'age_DESC'
        @records = @records.order(created_at: :asc)
      when 'status_ASC'
        @records = @records.order(:my_module_status_id)
      when 'status_DESC'
        @records = @records.order(my_module_status_id: :desc)
      when  'comments_ASC'
        @records = @records.order('comment_count ASC')
      when  'comments_DESC'
        @records = @records.order('comment_count DESC')
      when 'designated_ASC'
        @records = @records.order('designated_count ASC')
      when 'designated_DESC'
        @records = @records.order('designated_count DESC')
      when 'results_ASC'
        @records = @records.order('result_count ASC')
      when 'results_DESC'
        @records = @records.order('result_count DESC')
      when 'tags_ASC'
        @records = @records.order('tag_count ASC')
      when 'tags_DESC'
        @records = @records.order('tag_count DESC')
      when 'favorite_ASC'
        @records = @records.order(favorite: :desc)
      when 'favorite_DESC'
        @records = @records.order(:favorite)
      else
        __send__("#{sortable_columns[order_params[:column].to_sym]}_sort", sort_direction(order_params))
      end

      @records = @records.distinct('my_modules.id')
    end

    def query_filter(value)
      @records = @records.where_attributes_like('my_modules.name', value)
    end

    def due_date_from_filter(value)
      @records = @records.where('my_modules.due_date >= ?', value)
    end

    def due_date_to_filter(value)
      @records = @records.where('my_modules.due_date <= ?', value)
    end

    def archived_on_from_filter(value)
      @records = @records.where('my_modules.archived_on >= ?', value)
    end

    def archived_on_to_filter(value)
      @records = @records.where('my_modules.archived_on <= ?', value)
    end

    def designated_users_filter(users)
      @records = @records.joins(:user_my_modules).where(user_my_modules: { user_id: users.values })
    end

    def statuses_filter(statuses)
      @records = @records.where(my_module_status_id: statuses.values)
    end
  end
end
