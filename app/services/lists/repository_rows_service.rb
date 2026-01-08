# frozen_string_literal: true

module Lists
  module RepositoryFilters
    class ColumnNotFoundException < StandardError; end

    class ValueNotFoundException < StandardError; end
  end

  class RepositoryRowsService < BaseService
    PREDEFINED_COLUMNS = %w(row_id row_name added_on added_by archived_on archived_by assigned relationships updated_on updated_by).freeze

    def initialize(raw_data, params, user: nil, my_module: nil, assigned_view: false, disable_reminders: false, preload_cells: true, page: nil)
      super(raw_data, params, user: user)
      @repository = @raw_data
      @my_module = my_module
      @assigned_view = assigned_view
      @disable_reminders = disable_reminders
      @preload_cells = preload_cells
      @page = page
    end

    def call
      fetch_records
      filter_records
      sort_records
      paginate_records
      add_extra_fields
      paginate_records
      @records
    end

    private

    def fetch_records
      @records = @repository.repository_rows
      @records = @records.joins(:my_module_repository_rows).where(my_module_repository_rows: { my_module_id: @my_module }) if @my_module && @assigned_view
    end

    def add_extra_fields
      @records = @records.select('repository_rows.id')
                         .select('COUNT("repository_rows"."id") OVER() AS filtered_count')
      @records = RepositoryRow.with(paginated_repository_rows: @records)
                              .joins('JOIN paginated_repository_rows ON paginated_repository_rows.id = repository_rows.id')

      # Adding assigned counters
      if @my_module
        if @assigned_view
          @records = @records.joins(:my_module_repository_rows).where(my_module_repository_rows: { my_module_id: @my_module })
          @records = @records.select('SUM(DISTINCT my_module_repository_rows.stock_consumption) AS "consumed_stock"') if @repository.has_stock_management?
        else
          @records = @records.left_outer_joins(:my_module_repository_rows)
          @records = @records.where(my_module_repository_rows: { my_module: @my_module }).or(@records.active)
          @records = @records.select("EXISTS (SELECT 1 FROM my_module_repository_rows " \
                                     "WHERE my_module_repository_rows.repository_row_id = repository_rows.id " \
                                     "AND my_module_repository_rows.my_module_id = #{@my_module.id}) AS assigned")
        end
      else
        @records = @records.left_outer_joins(:my_module_repository_rows)
      end

      if Repository.reminders_enabled? && !@disable_reminders
        @records =
          if @repository.archived? || @repository.is_a?(RepositorySnapshot)
            # don't load reminders for archived repositories or snapshots
            @records.select('FALSE AS has_active_reminders')
          else
            @records.select("EXISTS (#{RepositoryCell.with_active_reminder(@user)
                                                     .joins(:repository_column)
                                                     .where(repository_column: { repository: @repository })
                                                     .where('repository_cells.repository_row_id = repository_rows.id')
                                                     .select(1)
                                                     .to_sql}) AS has_active_reminders")
          end
      end

      @records = @records.joins('LEFT OUTER JOIN "users" "created_by" ON "created_by"."id" = "repository_rows"."created_by_id"')
                         .joins('LEFT OUTER JOIN "users" "last_modified_by" ON "last_modified_by"."id" = "repository_rows"."last_modified_by_id"')
                         .joins('LEFT OUTER JOIN "users" "archived_by" ON "archived_by"."id" = "repository_rows"."archived_by_id"')
                         .select('repository_rows.*')
                         .select('MAX("paginated_repository_rows"."filtered_count") AS filtered_count')
                         .select('MAX("created_by"."full_name") AS created_by_full_name')
                         .select('MAX("last_modified_by"."full_name") AS last_modified_by_full_name')
                         .select('MAX("archived_by"."full_name") AS archived_by_full_name')
                         .select('COUNT(DISTINCT my_module_repository_rows.id) AS "assigned_my_modules_count"')
                         .select('COALESCE(repository_rows.parent_connections_count, 0) + COALESCE(repository_rows.child_connections_count, 0) AS "relationships_count"')
                         .group('repository_rows.id')
                         .preload(:repository)

      @records = @records.preload(:repository_columns, repository_cells: { value: @repository.cell_preload_includes }) if @preload_cells
      @records = @records.preload(:repository_stock_cell, :repository_stock_value) if @repository.has_stock_management?
    end

    # Filtering logic

    def filter_records
      @records = @records.where(archived: @params[:archived]) if @params[:archived] && !@repository.archived?
      @records = @records.where(external_id: @params[:external_ids]) if @params[:external_ids]

      # filter only rows with reminders if filter param is present
      @records = @records.with_active_reminders(@repository, @user) if @params[:only_reminders]

      if @params[:search].present?
        @records = @records.joins(:created_by) if @repository.default_search_fileds.include?('users.full_name')
        data_types = @repository.repository_columns.pluck(:data_type).uniq

        filtered_records = @records.where_attributes_like(@repository.default_search_fileds, @params[:search])

        Extends::AG_REPOSITORY_EXTRA_SEARCH_ATTR.each do |data_type, config|
          next unless data_types.include?(data_type.to_s)

          filtered_records = filtered_records.or(@records.where('EXISTS (?)',
                                                                data_type.to_s.constantize
                                                                         .joins(:repository_cell)
                                                                         .joins(config[:includes])
                                                                         .where('repository_cells.repository_row_id = repository_rows.id')
                                                                         .where_attributes_like(config[:field], @params[:search])
                                                                         .select(1)))
        end

        @records = filtered_records
      elsif @params.dig(:advanced_search, :filter_elements).present?
        filter = @repository.repository_table_filters.new
        @params[:advanced_search][:filter_elements].each_with_index do |filter_element_params, index|
          if PREDEFINED_COLUMNS.include?(filter_element_params[:repository_column_id])
            add_predefined_column_filter_condition(filter_element_params)
          else
            add_custom_column_filter_condition(filter, index, filter_element_params)
          end
        end
      end
    end

    def add_predefined_column_filter_condition(filter_element_params)
      @records =
        case filter_element_params[:repository_column_id]
        when 'row_id'
          build_row_id_filter_condition(filter_element_params)
        when 'row_name'
          build_name_filter_condition(filter_element_params)
        when 'relationships'
          build_relationship_filter_condition(filter_element_params)
        when 'added_on'
          build_added_on_filter_condition(filter_element_params)
        when 'added_by'
          build_added_by_filter_condition(filter_element_params)
        when 'updated_on'
          build_updated_on_filter_condition(filter_element_params)
        when 'updated_by'
          build_updated_by_filter_condition(filter_element_params)
        when 'archived_by'
          build_archived_by_filter_condition(filter_element_params)
        when 'archived_on'
          build_archived_on_filter_condition(filter_element_params)
        when 'assigned'
          build_assigned_filter_condition(filter_element_params)
        end
    end

    def build_row_id_filter_condition(filter_element_params)
      return @records if filter_element_params.dig(:parameters, :text).blank?

      case filter_element_params[:operator]
      when 'contains'
        @records.where("(#{RepositoryRow::PREFIXED_ID_SQL})::text ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
      when 'doesnt_contain'
        @records.where.not("(#{RepositoryRow::PREFIXED_ID_SQL})::text ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow ID!'
      end
    end

    def build_name_filter_condition(filter_element_params)
      return @records if filter_element_params.dig(:parameters, :text).blank?

      case filter_element_params[:operator]
      when 'contains'
        @records.where('repository_rows.name ILIKE ?', "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
      when 'doesnt_contain'
        @records.where.not('repository_rows.name ILIKE ?', "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Name!'
      end
    end

    def build_relationship_filter_condition(filter_element_params)
      case filter_element_params[:operator]
      when 'contains'
        text = "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%"

        @records.where(
          id: @records.left_outer_joins(:parent_repository_rows, :child_repository_rows)
                      .where("trim_html_tags(child_repository_rows_repository_rows.name)::text ILIKE ? OR
                             trim_html_tags(parent_repository_rows_repository_rows.name)::text ILIKE ? OR
                             ('#{RepositoryRow::ID_PREFIX}' ||
                             child_repository_rows_repository_rows.id)::text ILIKE ? OR
                             ('#{RepositoryRow::ID_PREFIX}' ||
                             parent_repository_rows_repository_rows.id)::text ILIKE ?",
                             text, text, text, text).select(:id)
        )
      when 'contains_relationship'
        @records.left_outer_joins(:parent_connections, :child_connections)
                .where.not(parent_connections: { id: nil })
                .or(@records.where.not(child_connections: { id: nil }))
      when 'doesnt_contain_relationship'
        @records.where.missing(:parent_connections, :child_connections)
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Relationship!'
      end
    end

    def build_added_on_filter_condition(filter_element_params)
      case filter_element_params[:operator]
      when 'today'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
          Time.zone.now.beginning_of_day, Time.zone.now.end_of_day
        )
      when 'yesterday'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
          Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day
        )
      when 'last_week'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
          Time.zone.now.beginning_of_week - 1.week, Time.zone.now.beginning_of_week
        )
      when 'this_month'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND date_trunc('minute', \"repository_rows\".\"created_at\") <= ?",
          Time.zone.now.beginning_of_month, Time.zone.now.end_of_month
        )
      when 'last_year'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
          Time.zone.now.beginning_of_year - 1.year, Time.zone.now.beginning_of_year
        )
      when 'this_year'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND date_trunc('minute', \"repository_rows\".\"created_at\") <= ?",
          Time.zone.now.beginning_of_year, Time.zone.now.end_of_year
        )
      when 'equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"created_at\") = ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'unequal_to'
        @records.where.not("date_trunc('minute', \"repository_rows\".\"created_at\") = ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'greater_than'
        @records.where("date_trunc('minute', \"repository_rows\".\"created_at\") > ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'greater_than_or_equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"created_at\") >= ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'less_than'
        @records.where("date_trunc('minute', \"repository_rows\".\"created_at\") < ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'less_than_or_equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"created_at\") <= ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'between'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"created_at\") > ? AND "\
          "date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
          Time.zone.parse(filter_element_params.dig(:parameters, :start_datetime)),
          Time.zone.parse(filter_element_params.dig(:parameters, :end_datetime))
        )
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Added On!'
      end
    end

    def build_archived_on_filter_condition(filter_element_params)
      return @records unless @params[:archived]

      case filter_element_params[:operator]
      when 'today'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?",
                       Time.zone.now.beginning_of_day, Time.zone.now.end_of_day)
      when 'yesterday'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                       Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day)
      when 'last_week'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                       Time.zone.now.beginning_of_week - 1.week, Time.zone.now.beginning_of_week)
      when 'this_month'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?",
          Time.zone.now.beginning_of_month,
          Time.zone.now.end_of_month
        )
      when 'last_year'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                       Time.zone.now.beginning_of_year - 1.year, Time.zone.now.beginning_of_year)
      when 'this_year'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND " \
          "date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?",
          Time.zone.now.beginning_of_year,
          Time.zone.now.end_of_year
        )
      when 'equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") = ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'unequal_to'
        @records.where.not("date_trunc('minute', \"repository_rows\".\"archived_on\") = ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'greater_than'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") > ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'greater_than_or_equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'less_than'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") < ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'less_than_or_equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'between'
        @records.where("date_trunc('minute', \"repository_rows\".\"archived_on\") > ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                       Time.zone.parse(filter_element_params.dig(:parameters, :start_datetime)),
                       Time.zone.parse(filter_element_params.dig(:parameters, :end_datetime)))
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Archived On!'
      end
    end

    def build_updated_on_filter_condition(filter_element_params)
      case filter_element_params[:operator]
      when 'today'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"updated_at\") >= ? AND " \
          "date_trunc('minute', \"repository_rows\".\"updated_at\") < ?",
          Time.zone.now.beginning_of_day,
          Time.zone.now.end_of_day
        )
      when 'yesterday'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"updated_at\") >= ? AND " \
          "date_trunc('minute', \"repository_rows\".\"updated_at\") < ?",
          Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day
        )
      when 'last_week'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"updated_at\") >= ? AND " \
          "date_trunc('minute', \"repository_rows\".\"updated_at\") < ?",
          Time.zone.now.beginning_of_week - 1.week, Time.zone.now.beginning_of_week
        )
      when 'this_month'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"updated_at\") >= ? AND " \
          "date_trunc('minute', \"repository_rows\".\"updated_at\") <= ?",
          Time.zone.now.beginning_of_month,
          Time.zone.now.end_of_month
        )
      when 'last_year'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"updated_at\") >= ? AND " \
          "date_trunc('minute', \"repository_rows\".\"updated_at\") < ?",
          Time.zone.now.beginning_of_year - 1.year, Time.zone.now.beginning_of_year
        )
      when 'this_year'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"updated_at\") >= ? AND " \
          "date_trunc('minute', \"repository_rows\".\"updated_at\") <= ?",
          Time.zone.now.beginning_of_year,
          Time.zone.now.end_of_year
        )
      when 'equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"updated_at\") = ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'unequal_to'
        @records.where.not("date_trunc('minute', \"repository_rows\".\"updated_at\") = ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'greater_than'
        @records.where("date_trunc('minute', \"repository_rows\".\"updated_at\") > ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'greater_than_or_equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"updated_at\") >= ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'less_than'
        @records.where("date_trunc('minute', \"repository_rows\".\"updated_at\") < ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'less_than_or_equal_to'
        @records.where("date_trunc('minute', \"repository_rows\".\"updated_at\") <= ?", Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
      when 'between'
        @records.where(
          "date_trunc('minute', \"repository_rows\".\"updated_at\") > ? AND "\
          "date_trunc('minute', \"repository_rows\".\"updated_at\") < ?",
          Time.zone.parse(filter_element_params.dig(:parameters, :start_datetime)),
          Time.zone.parse(filter_element_params.dig(:parameters, :end_datetime))
        )
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Updated on!'
      end
    end

    def build_added_by_filter_condition(filter_element_params)
      case filter_element_params[:operator]
      when 'any_of'
        @records.joins(:created_by).where(created_by: { id: filter_element_params.dig(:parameters, :user_ids) })
      when 'none_of'
        @records.joins(:created_by).where.not(created_by: { id: filter_element_params.dig(:parameters, :user_ids) })
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Added By!'
      end
    end

    def build_archived_by_filter_condition(filter_element_params)
      return @records unless @params[:archived]

      case filter_element_params[:operator]
      when 'any_of'
        @records.joins(:archived_by).where(archived_by: { id: filter_element_params.dig(:parameters, :user_ids) })
      when 'none_of'
        @records.joins(:archived_by).where.not(archived_by: { id: filter_element_params.dig(:parameters, :user_ids) })
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Archived By!'
      end
    end

    def build_updated_by_filter_condition(filter_element_params)
      case filter_element_params[:operator]
      when 'any_of'
        @records.joins(:last_modified_by).where(last_modified_by: { id: filter_element_params.dig(:parameters, :user_ids) })
      when 'none_of'
        @records.joins(:last_modified_by).where.not(last_modified_by: { id: filter_element_params.dig(:parameters, :user_ids) })
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Updated By!'
      end
    end

    def build_assigned_filter_condition(filter_element_params)
      return @records if filter_element_params.dig(:parameters, :my_module_ids).blank?

      case filter_element_params[:operator]
      when 'any_of'
        @records.joins(:my_modules).where(my_modules: { id: filter_element_params.dig(:parameters, :my_module_ids) })
      when 'none_of'
        @records.where('NOT EXISTS (SELECT NULL FROM my_module_repository_rows
                       WHERE my_module_repository_rows.repository_row_id = repository_rows.id AND
                       my_module_repository_rows.my_module_id IN (?))', filter_element_params.dig(:parameters, :my_module_ids))
      when 'all_of'
        @records
          .joins(:my_modules)
          .where(my_modules: { id: filter_element_params.dig(:parameters, :my_module_ids) })
          .having('COUNT(my_modules.id) = ?', filter_element_params.dig(:parameters, :my_module_ids).count)
          .group(:id)
      else
        raise ArgumentError, 'Wrong operator for RepositoryRow Assigned To!'
      end
    end

    def add_custom_column_filter_condition(filter, index, filter_element_params)
      repository_column = @repository.repository_columns.find_by(id: filter_element_params[:repository_column_id])
      raise RepositoryFilters::ColumnNotFoundException unless repository_column

      filter_element = filter.repository_table_filter_elements.new(
        repository_column: repository_column,
        operator: filter_element_params[:operator],
        parameters: filter_element_params[:parameters]
      )
      config = Extends::REPOSITORY_ADVANCED_SEARCH_ATTR[filter_element.repository_column.data_type.to_sym]
      join_cells_alias = "repository_cells_#{index}"
      join_values_alias = "repository_values_#{index}"

      enforce_referenced_value_existence!(filter_element)

      @records =
        @records
        .joins(
          "LEFT OUTER JOIN \"repository_cells\" AS \"#{join_cells_alias}\" " \
          "ON  \"repository_rows\".\"id\" = \"#{join_cells_alias}\".\"repository_row_id\" " \
          "AND \"#{join_cells_alias}\".\"repository_column_id\" = '#{filter_element.repository_column.id}'"
        ).joins(
          "LEFT OUTER JOIN \"#{config[:table_name]}\" AS \"#{join_values_alias}\" " \
          "ON  \"#{join_values_alias}\".\"id\" = \"#{join_cells_alias}\".\"value_id\""
        )

      @records =
        if %w(empty file_not_attached).include?(filter_element_params[:operator])
          @records.where(join_values_alias => { id: nil })
        else
          value_klass = filter_element.repository_column.data_type.constantize
          value_klass.add_filter_condition(@records, join_values_alias, filter_element)
        end
    end

    def enforce_referenced_value_existence!(filter_element)
      relation_method = Extends::REPOSITORY_ADVANCED_SEARCH_REFERENCED_VALUE_RELATIONS[filter_element.repository_column.data_type.to_sym]
      return unless relation_method

      relation = filter_element.repository_column.public_send(relation_method)
      value_item_ids = filter_element.parameters['item_ids']
      raise RepositoryFilters::ValueNotFoundException if relation.where(id: value_item_ids).count != value_item_ids.length
    end

    # Sorting logic

    def sort_records
      column = @params.dig(:order, :column)
      direction = @params.dig(:order, :dir)
      return unless column.present? && direction.present?

      direction = direction == 'desc' ? :desc : :asc

      case column
      when 'assigned'
        return if @my_module && @assigned_view

        @records = @records.order(assigned_my_modules_count: direction)
      when /^column_[1-9]\d*\z/
        column_id = column[/\d+\z/].to_i
        sorting_column = @repository.repository_columns.find_by(id: column_id)
        return unless sorting_column

        sorting_data_type = sorting_column.data_type.constantize
        cells = sorting_data_type.joins(
          "INNER JOIN repository_cells AS repository_sort_cells " \
          "ON repository_sort_cells.value_id = #{sorting_data_type.table_name}.id " \
          "AND repository_sort_cells.value_type = '#{sorting_data_type.base_class.name}'"
        ).where('repository_sort_cells.repository_column_id': sorting_column.id)

        cells = cells.joins(sorting_data_type::EXTRA_SORTABLE_VALUE_INCLUDE) if sorting_data_type.const_defined?('EXTRA_SORTABLE_VALUE_INCLUDE')

        cells = if sorting_column.repository_checklist_value?
                  cells.select("repository_sort_cells.repository_row_id, \
                               STRING_AGG(#{sorting_data_type::SORTABLE_COLUMN_NAME}, ' ' \
                               ORDER BY #{sorting_data_type::SORTABLE_COLUMN_NAME}) AS value")
                       .group('repository_sort_cells.repository_row_id')
                else
                  cells.select("repository_sort_cells.repository_row_id, #{sorting_data_type::SORTABLE_COLUMN_NAME} AS value")
                end

        @records = @records.joins("LEFT OUTER JOIN (#{cells.to_sql}) AS values ON values.repository_row_id = repository_rows.id")
                           .group('values.value')
                           .order('values.value' => direction)
      when 'users.full_name'
        @records = @records.group('created_by.full_name').order('created_by.full_name' => direction)
      when 'relationships'
        @records = @records.order(relationships_count: direction)
      else
        return unless sortable_columns.include?(column)

        @records = @records.group(:id).group(column).order(column => direction)
      end
    end

    def sortable_columns
      @sortable_columns ||= build_sortable_columns
    end

    def build_sortable_columns
      sortable_columns = @repository.default_sortable_columns
      sortable_columns << 'consumed_stock' if @repository.has_stock_management? && @assigned_view
      sortable_columns
    end
  end
end
