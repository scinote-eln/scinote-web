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
                          .select('my_modules.*')
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
        due_date: 'due_date',
        name: 'name',
        code: 'id',
        archived_on: 'archived_on',
        age: 'age',
        status: 'status',
        designated: 'designated',
        results: 'results',
        tags: 'tags',
        signatures: 'signatures'
      }
    end

    def sort_records
      return unless @params[:order]

      sort = "#{sortable_columns[order_params[:column].to_sym]}_#{sort_direction(order_params)}"

      case sort
      when 'due_date_ASC'
        @records = @records.order(:due_date, :name)
      when 'due_date_DESC'
        @records = @records.order(Arel.sql("COALESCE(due_date, DATE '2100-01-01') DESC"), :name)
      when 'name_ASC'
        @records = @records.order(:name)
      when 'name_DESC'
        @records = @records.order(name: :desc)
      when 'id_ASC'
        @records = @records.order(:id)
      when 'id_DESC'
        @records = @records.order(id: :desc)
      when 'archived_on_ASC'
        @records = @records.order(Arel.sql('COALESCE(my_modules.archived_on, my_modules.archived_on) ASC'))
      when 'archived_on_DESC'
        @records = @records.order(Arel.sql('COALESCE(my_modules.archived_on, my_modules.archived_on) DESC'))
      when 'age_ASC'
        @records = @records.order(:created_at)
      when 'age_DESC'
        @records = @records.order(created_at: :desc)
      when 'status_ASC'
        @records = @records.order(:my_module_status_id)
      when 'status_DESC'
        @records = @records.order(my_module_status_id: :desc)
      when 'designated_ASC'
        @records = @records.left_joins(:user_my_modules)
                           .group('my_modules.id')
                           .order(Arel.sql('COUNT(DISTINCT user_my_modules.id) ASC'))
      when 'designated_DESC'
        @records = @records.left_joins(:user_my_modules)
                           .group('my_modules.id')
                           .order(Arel.sql('COUNT(DISTINCT user_my_modules.id) DESC'))
      when 'results_ASC'
        @records = @records.left_joins(:results)
                           .group('my_modules.id')
                           .order(Arel.sql('COUNT(DISTINCT results.id) ASC'))
      when 'results_DESC'
        @records = @records.left_joins(:results)
                           .group('my_modules.id')
                           .order(Arel.sql('COUNT(DISTINCT results.id) DESC'))
      when 'tags_ASC'
        @records = @records.left_joins(:tags)
                           .group('my_modules.id')
                           .order(Arel.sql('COUNT(DISTINCT tags.id) ASC'))
      when 'tags_DESC'
        @records = @records.left_joins(:tags)
                           .group('my_modules.id')
                           .order(Arel.sql('COUNT(DISTINCT tags.id) DESC'))
      else
        __send__("#{sortable_columns[order_params[:column].to_sym]}_sort", sort_direction(order_params))
      end
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
