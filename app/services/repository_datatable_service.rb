# frozen_string_literal: true

class RepositoryDatatableService
  attr_reader :repository_rows, :all_count, :mappings

  def initialize(repository, params, user, my_module = nil)
    @repository = repository
    @user = user
    @my_module = my_module
    @params = params
    @sortable_columns = build_sortable_columns
    create_columns_mappings
    process_query
  end

  private

  def create_columns_mappings
    # Make mappings of custom columns, so we have same id for every
    # column
    index = 6
    @mappings = {}
    @repository.repository_columns.order(:id).each do |column|
      @mappings[column.id] = index.to_s
      index += 1
    end
  end

  def process_query
    search_value = build_conditions(@params)[:search_value]
    order_obj = build_conditions(@params)[:order_by_column]

    repository_rows = fetch_rows(search_value)

    # Adding assigned counters
    if @my_module
      if @params[:assigned] == 'assigned'
        repository_rows = repository_rows.joins(:my_module_repository_rows)
                                         .where(my_module_repository_rows: { my_module_id: @my_module })
      else
        repository_rows = repository_rows.joins(
          'LEFT OUTER JOIN "my_module_repository_rows" '\
          'ON "my_module_repository_rows"."repository_row_id" = "repository_rows"."id" '\
          'AND "my_module_repository_rows"."my_module_id" = ' + @my_module.id.to_s
        )
      end
      repository_rows = repository_rows.select('COUNT(my_module_repository_rows.id) AS "assigned_my_modules_count"')
    else
      repository_rows = repository_rows
                        .left_outer_joins(my_module_repository_rows: { my_module: :experiment })
                        .select('COUNT(my_module_repository_rows.id) AS "assigned_my_modules_count"')
                        .select('COUNT(DISTINCT my_modules.experiment_id) AS "assigned_experiments_count"')
                        .select('COUNT(DISTINCT experiments.project_id) AS "assigned_projects_count"')
    end
    repository_rows = repository_rows.preload(Extends::REPOSITORY_ROWS_PRELOAD_RELATIONS)

    @repository_rows = sort_rows(order_obj, repository_rows)
  end

  def fetch_rows(search_value)
    repository_rows = @repository.repository_rows

    @all_count =
      if @my_module && @params[:assigned] == 'assigned'
        repository_rows.joins(:my_module_repository_rows)
                       .where(my_module_repository_rows: { my_module_id: @my_module })
                       .count
      else
        repository_rows.count
      end

    if search_value.present?
      matched_by_user = repository_rows.joins(:created_by).where_attributes_like('users.full_name', search_value)

      repository_row_matches = repository_rows
                               .where_attributes_like(['repository_rows.name', 'repository_rows.id'], search_value)
      results = repository_rows.where(id: repository_row_matches)
      results = results.or(repository_rows.where(id: matched_by_user))

      Extends::REPOSITORY_EXTRA_SEARCH_ATTR.each do |field, include_hash|
        custom_cell_matches = repository_rows.joins(repository_cells: include_hash)
                                             .where_attributes_like(field, search_value)
        results = results.or(repository_rows.where(id: custom_cell_matches))
      end

      repository_rows = results
    end

    repository_rows.left_outer_joins(:created_by)
                   .select('repository_rows.*')
                   .select('COUNT("repository_rows"."id") OVER() AS filtered_count')
                   .group('repository_rows.id')
  end

  def build_conditions(params)
    search_value = params[:search][:value]
    order = params[:order].values.first
    order_by_column = { column: order[:column].to_i,
                        dir: order[:dir] }
    { search_value: search_value, order_by_column: order_by_column }
  end

  def build_sortable_columns
    array = [
      'assigned',
      'repository_rows.id',
      'repository_rows.name',
      'repository_rows.created_at',
      'users.full_name'
    ]
    @repository.repository_columns.count.times do
      array << 'repository_cell.value'
    end
    array
  end

  def sort_rows(column_obj, records)
    dir = %w(DESC ASC).find do |direction|
      direction == column_obj[:dir].upcase
    end || 'ASC'

    column_index = column_obj[:column]
    service = RepositoryTableStateService.new(@user, @repository)
    col_order = service.load_state.state['ColReorder']
    column_id = col_order[column_index].to_i

    if @sortable_columns[column_id - 1] == 'assigned'
      return records if @my_module && @params[:assigned] == 'assigned'

      records.order("assigned_my_modules_count #{dir}")
    elsif @sortable_columns[column_id - 1] == 'repository_cell.value'
      id = @mappings.key(column_id.to_s)
      sorting_column = RepositoryColumn.find_by(id: id)
      return records unless sorting_column

      sorting_data_type = sorting_column.data_type.constantize

      if sorting_column.repository_checklist_value?
        cells = RepositoryCell.joins(sorting_data_type::SORTABLE_VALUE_INCLUDE)
                              .where('repository_cells.repository_column_id': sorting_column.id)
                              .select("repository_cells.repository_row_id,
                                              STRING_AGG(
                                                #{sorting_data_type::SORTABLE_COLUMN_NAME}, ' '
                                                ORDER BY #{sorting_data_type::SORTABLE_COLUMN_NAME}) AS value")
                              .group('repository_cells.repository_row_id')

      else
        cells = RepositoryCell.joins(sorting_data_type::SORTABLE_VALUE_INCLUDE)
                              .where('repository_cells.repository_column_id': sorting_column.id)
                              .select("repository_cells.repository_row_id,
                                      #{sorting_data_type::SORTABLE_COLUMN_NAME} AS value")
      end

      records.joins("LEFT OUTER JOIN (#{cells.to_sql}) AS values ON values.repository_row_id = repository_rows.id")
             .group('values.value')
             .order("values.value #{dir}")
    elsif @sortable_columns[column_id - 1] == 'users.full_name'
      records.group('users.full_name').order("users.full_name #{dir}")
    else
      records.group(@sortable_columns[column_id - 1]).order("#{@sortable_columns[column_id - 1]} #{dir}")
    end
  end
end
