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
    search_value = build_conditions(@params)[:search_value]
    order_obj = build_conditions(@params)[:order_by_column]

    repository_rows = fetch_rows(search_value)

    # Adding assigned counters
    if @my_module
      if @params[:assigned] == 'assigned'
        repository_rows = repository_rows.joins(:my_module_repository_rows)
                                         .where(my_module_repository_rows: { my_module_id: @my_module })
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
                      .select('COUNT(my_module_repository_rows.id) AS "assigned_my_modules_count"')
                      .select('COUNT(DISTINCT my_modules.experiment_id) AS "assigned_experiments_count"')
                      .select('COUNT(DISTINCT experiments.project_id) AS "assigned_projects_count"')
    repository_rows = repository_rows.preload(Extends::REPOSITORY_ROWS_PRELOAD_RELATIONS)

    sort_rows(order_obj, repository_rows)
  end

  def fetch_rows(search_value)
    repository_rows = @repository.repository_rows
    if @params[:archived] && !@repository.archived?
      repository_rows = repository_rows.where(archived: @params[:archived])
    end

    @all_count =
      if @my_module && @params[:assigned] == 'assigned'
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

    repository_rows.left_outer_joins(:created_by, :archived_by)
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
    array = @repository.default_sortable_columns
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

    case @sortable_columns[column_id - 1]
    when 'assigned'
      return records if @my_module && @params[:assigned] == 'assigned'

      records.order("assigned_my_modules_count #{dir}")
    when 'repository_cell.value'
      id = @mappings.key(column_id.to_s)
      sorting_column = @repository.repository_columns.find_by(id: id)
      return records unless sorting_column

      sorting_data_type = sorting_column.data_type.constantize
      cells = sorting_data_type.joins(:repository_cell)
                               .where('repository_cells.repository_column_id': sorting_column.id)
      if sorting_data_type.const_defined?('EXTRA_SORTABLE_VALUE_INCLUDE')
        cells = cells.joins(sorting_data_type::EXTRA_SORTABLE_VALUE_INCLUDE)
      end

      cells = if sorting_column.repository_checklist_value?
                cells
                  .select("repository_cells.repository_row_id, \
                           STRING_AGG(#{sorting_data_type::SORTABLE_COLUMN_NAME}, ' ' \
                           ORDER BY #{sorting_data_type::SORTABLE_COLUMN_NAME}) AS value")
                  .group('repository_cells.repository_row_id')
              else
                cells
                  .select("repository_cells.repository_row_id, #{sorting_data_type::SORTABLE_COLUMN_NAME} AS value")
              end

      records.joins("LEFT OUTER JOIN (#{cells.to_sql}) AS values ON values.repository_row_id = repository_rows.id")
             .group('values.value')
             .order("values.value #{dir}")
    when 'users.full_name'
      records.group('users.full_name').order("users.full_name #{dir}")
    else
      records.group(@sortable_columns[column_id - 1]).order("#{@sortable_columns[column_id - 1]} #{dir}")
    end
  end
end
