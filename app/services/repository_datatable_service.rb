# frozen_string_literal: true

module RepositoryFilters
  class ColumnNotFoundException < StandardError; end

  class ValueNotFoundException < StandardError; end
end

class RepositoryDatatableService
  include MyModulesHelper
  attr_reader :repository_rows, :all_count, :mappings

  PREDEFINED_COLUMNS = %w(row_id row_name added_on added_by archived_on archived_by assigned relationships).freeze

  def initialize(repository, params, user, my_module = nil)
    @repository = repository
    @user = user
    @my_module = my_module
    @params = params
    @assigned_view =  @params[:assigned].in?(%w(assigned assigned_simple))
    @sortable_columns = build_sortable_columns
    create_columns_mappings
    @repository_rows = process_query
  end

  private

  def create_columns_mappings
    # Make mappings of custom columns, so we have same id for every
    # column
    index = @repository.default_columns_count
    @mappings = {}
    @repository.repository_columns.order(:id).each do |column|
      @mappings[column.id] = index.to_s
      index += 1
    end
  end

  def process_query
    search_value = @params[:search][:value]
    order_params = @params[:order].first

    order_by_column = { column: order_params[:column].to_i, dir: order_params[:dir] }

    repository_rows = fetch_rows(search_value)

    # filter only rows with reminders if filter param is present
    repository_rows = repository_rows.with_active_reminders(@user) if @params[:only_reminders]

    # Aliased my_module_repository_rows join for consistent assigned counts
    repository_rows =
      repository_rows.joins(
        'LEFT OUTER JOIN "my_module_repository_rows" AS "all_my_module_repository_rows" ON '\
        '"all_my_module_repository_rows"."repository_row_id" = "repository_rows"."id"'
      )

    # Adding assigned counters
    if @my_module
      if @assigned_view
        repository_rows = repository_rows.joins(:my_module_repository_rows)
                                         .where(my_module_repository_rows: { my_module_id: @my_module })
        if @repository.has_stock_management?
          repository_rows = repository_rows
                            .select('SUM(DISTINCT my_module_repository_rows.stock_consumption) AS "consumed_stock"')
        end
      else
        repository_rows = repository_rows
                          .joins(:repository)
                          .joins('LEFT OUTER JOIN "my_module_repository_rows" "current_my_module_repository_rows"'\
                                 'ON "current_my_module_repository_rows"."repository_row_id" = "repository_rows"."id" '\
                                 'AND "current_my_module_repository_rows"."my_module_id" = ' + @my_module.id.to_s)
                          .where('current_my_module_repository_rows.id IS NOT NULL '\
                                 'OR (repository_rows.archived = FALSE AND repositories.archived = FALSE)')
                          .select('CASE WHEN current_my_module_repository_rows.id IS NOT NULL '\
                                  'THEN true ELSE false END as row_assigned')
                          .group('current_my_module_repository_rows.id')
      end
    end
    repository_rows = repository_rows
                      .left_outer_joins(my_module_repository_rows: { my_module: :experiment })
                      .select('COUNT(DISTINCT all_my_module_repository_rows.id) AS "assigned_my_modules_count"')
                      .select('COUNT(DISTINCT my_modules.experiment_id) AS "assigned_experiments_count"')
                      .select('COUNT(DISTINCT experiments.project_id) AS "assigned_projects_count"')
                      .select('COALESCE(parent_connections_count, 0) + COALESCE(child_connections_count, 0)
                               AS "relationships_count"')
    repository_rows = repository_rows.preload(Extends::REPOSITORY_ROWS_PRELOAD_RELATIONS)

    sort_rows(order_by_column, repository_rows)
  end

  def fetch_rows(search_value)
    repository_rows = @repository.repository_rows
    if @params[:archived] && !@repository.archived?
      repository_rows = repository_rows.where(archived: @params[:archived])
    end

    @all_count =
      if @my_module && @assigned_view
        repository_rows.joins(:my_module_repository_rows)
                       .where(my_module_repository_rows: { my_module_id: @my_module })
                       .count
      else
        repository_rows.count
      end

    repository_rows = repository_rows.where(external_id: @params[:external_ids]) if @params[:external_ids]

    if search_value.present?
      if @repository.default_search_fileds.include?('users.full_name')
        repository_rows = repository_rows.joins(:created_by)
      end
      repository_row_matches = repository_rows.where_attributes_like(@repository.default_search_fileds, search_value)
      results = repository_rows.where(id: repository_row_matches)

      data_types = @repository.repository_columns.pluck(:data_type).uniq

      Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each do |data_type, config|
        next unless data_types.include?(data_type.to_s)

        custom_cell_matches = repository_rows.joins(config[:includes])
                                             .where_attributes_like(config[:field], search_value)
        results = results.or(repository_rows.where(id: custom_cell_matches))
      end

      repository_rows = results
    end

    repository_rows = repository_rows.where(id: advanced_search(repository_rows)) if @params[:advanced_search].present?

    repository_rows.left_outer_joins(:created_by, :archived_by)
                   .select('repository_rows.*')
                   .select('COUNT("repository_rows"."id") OVER() AS filtered_count')
                   .group('repository_rows.id')
  end

  def advanced_search(repository_rows)
    adv_search_params = @params[:advanced_search]
    filter = @repository.repository_table_filters.new
    adv_search_params[:filter_elements].each_with_index do |filter_element_params, index|
      repository_rows =
        if PREDEFINED_COLUMNS.include?(filter_element_params[:repository_column_id])
          add_predefined_column_filter_condition(repository_rows, filter_element_params)
        else
          add_custom_column_filter_condition(repository_rows, filter, index, filter_element_params)
        end
    end

    repository_rows
  end

  def add_predefined_column_filter_condition(repository_rows, filter_element_params)
    case filter_element_params[:repository_column_id]
    when 'row_id'
      build_row_id_filter_condition(repository_rows, filter_element_params)
    when 'row_name'
      build_name_filter_condition(repository_rows, filter_element_params)
    when 'relationships'
      build_relationship_filter_condition(repository_rows, filter_element_params)
    when 'added_on'
      build_added_on_filter_condition(repository_rows, filter_element_params)
    when 'added_by'
      build_added_by_filter_condition(repository_rows, filter_element_params)
    when 'archived_by'
      build_archived_by_filter_condition(repository_rows, filter_element_params)
    when 'archived_on'
      build_archived_on_filter_condition(repository_rows, filter_element_params)
    when 'assigned'
      build_assigned_filter_condition(repository_rows, filter_element_params)
    else
      repository_rows
    end
  end

  def build_row_id_filter_condition(repository_rows, filter_element_params)
    return repository_rows if filter_element_params.dig(:parameters, :text).blank?

    case filter_element_params[:operator]
    when 'contains'
      repository_rows
        .where("(#{RepositoryRow::PREFIXED_ID_SQL})::text ILIKE ?",
               "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
    when 'doesnt_contain'
      repository_rows
        .where.not("(#{RepositoryRow::PREFIXED_ID_SQL})::text ILIKE ?",
                   "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow ID!'
    end
  end

  def build_name_filter_condition(repository_rows, filter_element_params)
    return repository_rows if filter_element_params.dig(:parameters, :text).blank?

    case filter_element_params[:operator]
    when 'contains'
      repository_rows.where('repository_rows.name ILIKE ?',
                            "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
    when 'doesnt_contain'
      repository_rows
        .where.not('repository_rows.name ILIKE ?',
                   "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%")
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow Name!'
    end
  end

  def build_relationship_filter_condition(repository_rows, filter_element_params)
    case filter_element_params[:operator]
    when 'contains'
      text = "%#{ActiveRecord::Base.sanitize_sql_like(filter_element_params.dig(:parameters, :text))}%"

      repository_rows.where(
        id: repository_rows.left_outer_joins(:parent_repository_rows, :child_repository_rows)
                           .where("trim_html_tags(child_repository_rows_repository_rows.name)::text ILIKE ? OR
                                  trim_html_tags(parent_repository_rows_repository_rows.name)::text ILIKE ? OR
                                  ('#{RepositoryRow::ID_PREFIX}' ||
                                  child_repository_rows_repository_rows.id)::text ILIKE ? OR
                                  ('#{RepositoryRow::ID_PREFIX}' ||
                                  parent_repository_rows_repository_rows.id)::text ILIKE ?",
                                  text, text, text, text).select(:id)
      )
    when 'contains_relationship'
      repository_rows = repository_rows.left_outer_joins(:parent_connections, :child_connections)
      repository_rows.where.not(parent_connections: { id: nil })
                     .or(repository_rows.where.not(child_connections: { id: nil }))
    when 'doesnt_contain_relationship'
      repository_rows.where.missing(:parent_connections, :child_connections)
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow Relationship!'
    end
  end

  def build_added_on_filter_condition(repository_rows, filter_element_params)
    case filter_element_params[:operator]
    when 'today'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND " \
        "date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
        Time.zone.now.beginning_of_day,
        Time.zone.now.end_of_day
      )
    when 'yesterday'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND "\
        "date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
        Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day
      )
    when 'last_week'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND "\
        "date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
        Time.zone.now.beginning_of_week - 1.week, Time.zone.now.beginning_of_week
      )
    when 'this_month'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND date_trunc('minute', \"repository_rows\".\"created_at\") <= ?",
        Time.zone.now.beginning_of_month,
        Time.zone.now.end_of_month
      )
    when 'last_year'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND "\
        "date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
        Time.zone.now.beginning_of_year - 1.year, Time.zone.now.beginning_of_year
      )
    when 'this_year'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"created_at\") >= ? AND "\
        "date_trunc('minute', \"repository_rows\".\"created_at\") <= ?",
        Time.zone.now.beginning_of_year,
        Time.zone.now.end_of_year
      )
    when 'equal_to'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"created_at\") = ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'unequal_to'
      repository_rows.where.not("date_trunc('minute', \"repository_rows\".\"created_at\") = ?",
                                Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'greater_than'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"created_at\") > ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'greater_than_or_equal_to'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"created_at\") >= ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'less_than'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'less_than_or_equal_to'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"created_at\") <= ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'between'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"created_at\") > ? AND "\
        "date_trunc('minute', \"repository_rows\".\"created_at\") < ?",
        Time.zone.parse(filter_element_params.dig(:parameters, :start_datetime)),
        Time.zone.parse(filter_element_params.dig(:parameters, :end_datetime))
      )
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow Added On!'
    end
  end

  def build_archived_on_filter_condition(repository_rows, filter_element_params)
    return repository_rows unless @params[:archived]

    case filter_element_params[:operator]
    when 'today'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?",
                            Time.zone.now.beginning_of_day, Time.zone.now.end_of_day)
    when 'yesterday'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                            Time.zone.now.beginning_of_day - 1.day, Time.zone.now.beginning_of_day)
    when 'last_week'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                            Time.zone.now.beginning_of_week - 1.week, Time.zone.now.beginning_of_week)
    when 'this_month'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?",
        Time.zone.now.beginning_of_month,
        Time.zone.now.end_of_month
      )
    when 'last_year'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                            Time.zone.now.beginning_of_year - 1.year, Time.zone.now.beginning_of_year)
    when 'this_year'
      repository_rows.where(
        "date_trunc('minute', \"repository_rows\".\"archived_on\") >= ? AND "\
        "date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?",
        Time.zone.now.beginning_of_year,
        Time.zone.now.end_of_year
      )
    when 'equal_to'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") = ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'unequal_to'
      repository_rows.where.not("date_trunc('minute', \"repository_rows\".\"archived_on\") = ?",
                                Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'greater_than'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") > ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'greater_than_or_equal_to'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") >= ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'less_than'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'less_than_or_equal_to'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") <= ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :datetime)))
    when 'between'
      repository_rows.where("date_trunc('minute', \"repository_rows\".\"archived_on\") > ? AND date_trunc('minute', \"repository_rows\".\"archived_on\") < ?",
                            Time.zone.parse(filter_element_params.dig(:parameters, :start_datetime)),
                            Time.zone.parse(filter_element_params.dig(:parameters, :end_datetime)))
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow Archived On!'
    end
  end

  def build_added_by_filter_condition(repository_rows, filter_element_params)
    case filter_element_params[:operator]
    when 'any_of'
      repository_rows.joins(:created_by)
                     .where(created_by: { id: filter_element_params.dig(:parameters, :user_ids) })
    when 'none_of'
      repository_rows.joins(:created_by)
                     .where.not(created_by: { id: filter_element_params.dig(:parameters, :user_ids) })
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow Added By!'
    end
  end

  def build_archived_by_filter_condition(repository_rows, filter_element_params)
    return repository_rows unless @params[:archived]

    case filter_element_params[:operator]
    when 'any_of'
      repository_rows.joins(:archived_by)
                     .where(archived_by: { id: filter_element_params.dig(:parameters, :user_ids) })
    when 'none_of'
      repository_rows.joins(:archived_by)
                     .where.not(archived_by: { id: filter_element_params.dig(:parameters, :user_ids) })
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow Archived By!'
    end
  end

  def build_assigned_filter_condition(repository_rows, filter_element_params)
    return repository_rows if filter_element_params.dig(:parameters, :my_module_ids).blank?

    case filter_element_params[:operator]
    when 'any_of'
      repository_rows.joins(:my_modules)
                     .where(my_modules: { id: filter_element_params.dig(:parameters, :my_module_ids) })
    when 'none_of'
      repository_rows.where('NOT EXISTS (SELECT NULL FROM my_module_repository_rows
                             WHERE my_module_repository_rows.repository_row_id = repository_rows.id AND
                             my_module_repository_rows.my_module_id IN (?))', filter_element_params.dig(:parameters, :my_module_ids))
    when 'all_of'
      repository_rows
        .joins(:my_modules)
        .where(my_modules: { id: filter_element_params.dig(:parameters, :my_module_ids) })
        .having('COUNT(my_modules.id) = ?', filter_element_params.dig(:parameters, :my_module_ids).count)
        .group(:id)
    else
      raise ArgumentError, 'Wrong operator for RepositoryRow Assigned To!'
    end
  end

  def add_custom_column_filter_condition(repository_rows, filter, index, filter_element_params)
    repository_column = @repository.repository_columns.find_by(id: filter_element_params['repository_column_id'])
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

    repository_rows =
      repository_rows
      .joins(
        "LEFT OUTER JOIN \"repository_cells\" AS \"#{join_cells_alias}\"" \
        " ON  \"repository_rows\".\"id\" = \"#{join_cells_alias}\".\"repository_row_id\"" \
        " AND \"#{join_cells_alias}\".\"repository_column_id\" = '#{filter_element.repository_column.id}'"
      ).joins(
        "LEFT OUTER JOIN \"#{config[:table_name]}\" AS \"#{join_values_alias}\"" \
        " ON  \"#{join_values_alias}\".\"id\" = \"#{join_cells_alias}\".\"value_id\""
      )

    if %w(empty file_not_attached).include?(filter_element_params[:operator])
      repository_rows.where(join_values_alias => { id: nil })
    else
      value_klass = filter_element.repository_column.data_type.constantize
      value_klass.add_filter_condition(repository_rows, join_values_alias, filter_element)
    end
  end

  def enforce_referenced_value_existence!(filter_element)
    relation_method =
      Extends::REPOSITORY_ADVANCED_SEARCH_REFERENCED_VALUE_RELATIONS[
        filter_element.repository_column.data_type.to_sym
      ]

    return unless relation_method

    relation = filter_element.repository_column.public_send(relation_method)
    value_item_ids = filter_element.parameters['item_ids']
    raise RepositoryFilters::ValueNotFoundException if relation.where(id: value_item_ids).count != value_item_ids.length
  end

  def build_sortable_columns
    array = @repository.default_sortable_columns
    @repository.repository_columns.count.times do
      array << 'repository_cell.value'
    end

    array << 'consumed_stock' if @repository.has_stock_management? && @assigned_view
    array
  end

  def map_simple_view_column(index)
    return assigned_repository_simple_view_name_column_id(@repository) unless @repository.has_stock_management?

    case index
    when 0
      assigned_repository_simple_view_name_column_id(@repository)
    when 1
      @mappings[@repository.repository_stock_column.id]
    when 2
      @sortable_columns.length
    end
  end

  def sort_rows(column_obj, records)
    dir = %w(DESC ASC).find do |direction|
      direction == column_obj[:dir].upcase
    end || 'ASC'

    column_index = column_obj[:column]
    service = RepositoryTableStateService.new(@user, @repository)
    col_order = service.load_state.state['ColReorder']
    column_id = case @params[:assigned]
                when 'assigned_simple'
                  map_simple_view_column(column_index).to_i
                else
                  @params[:draw].to_i == 1 ? column_index.to_i : col_order[column_index].to_i
                end

    case @sortable_columns[column_id - 1]
    when 'assigned'
      return records if @my_module && @assigned_view

      records.order("assigned_my_modules_count #{dir}")
    when 'repository_cell.value'
      id = @mappings.key(column_id.to_s)
      sorting_column = @repository.repository_columns.find_by(id: id)
      return records unless sorting_column

      sorting_data_type = sorting_column.data_type.constantize
      cells = sorting_data_type.joins(
        "INNER JOIN repository_cells AS repository_sort_cells "\
        "ON repository_sort_cells.value_id = #{sorting_data_type.table_name}.id "\
        "AND repository_sort_cells.value_type = '#{sorting_data_type.base_class.name}'"
      ).where('repository_sort_cells.repository_column_id': sorting_column.id)

      if sorting_data_type.const_defined?('EXTRA_SORTABLE_VALUE_INCLUDE')
        cells = cells.joins(sorting_data_type::EXTRA_SORTABLE_VALUE_INCLUDE)
      end

      cells = if sorting_column.repository_checklist_value?
                cells
                  .select("repository_sort_cells.repository_row_id, \
                           STRING_AGG(#{sorting_data_type::SORTABLE_COLUMN_NAME}, ' ' \
                           ORDER BY #{sorting_data_type::SORTABLE_COLUMN_NAME}) AS value")
                  .group('repository_sort_cells.repository_row_id')
              else
                cells
                  .select("repository_sort_cells.repository_row_id, #{sorting_data_type::SORTABLE_COLUMN_NAME} AS value")
              end

      records.joins("LEFT OUTER JOIN (#{cells.to_sql}) AS values ON values.repository_row_id = repository_rows.id")
             .group('values.value')
             .order("values.value #{dir}")
    when 'users.full_name'
      records.group('users.full_name').order("users.full_name #{dir}")
    when 'consumed_stock'
      records.order("#{@sortable_columns[column_id - 1]} #{dir}")
    when 'relationships'
      records.order("relationships_count #{dir}")
    else
      records.group(@sortable_columns[column_id - 1]).order("#{@sortable_columns[column_id - 1]} #{dir}")
    end
  end
end
