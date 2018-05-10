class RepositoryDatatableService

  attr_reader :repository_rows, :assigned_rows, :mappings

  def initialize(repository, params, user, my_module = nil)
    @repository = repository
    @user = user
    @my_module = my_module
    @params = params
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
    order_obj = build_conditions(@params)[:order_by_column]
    search_value = build_conditions(@params)[:search_value]
    records = search_value.present? ? search(search_value) : fetch_records
    @repository_rows = sort_rows(order_obj, records)
  end

  def fetch_records
    repository_rows = RepositoryRow.preload(:repository_columns,
                                            :created_by,
                                            repository_cells: :value)
                                   .joins(:created_by)
                                   .where(repository: @repository)
    if @my_module
      @assigned_rows = @my_module.repository_rows
                                 .preload(
                                   :repository_columns,
                                   :created_by,
                                   repository_cells: :value
                                 )
                                 .joins(:created_by)
                                 .where(repository: @repository)
      return @assigned_rows if @params[:assigned] == 'assigned'
    else
      @assigned_rows = repository_rows.joins(:my_module_repository_rows)
    end
    repository_rows
  end

  def search(value)
    includes_json = { repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES }
    searchable_attributes = ['repository_rows.name',
                             'users.full_name',
                             'repository_rows.id'] +
                            Extends::REPOSITORY_EXTRA_SEARCH_ATTR
    ids = @repository.repository_rows
                     .left_outer_joins(:created_by)
                     .left_outer_joins(includes_json)
                     .where_attributes_like(searchable_attributes, value)
                     .pluck(:id)
    # using distinct raises an error when combined with sort
    RepositoryRow.where(id: ids.uniq)
  end

  def build_conditions(params)
    search_value = params[:search][:value]
    order = params[:order].values.first
    order_by_column = { column: order[:column].to_i,
                        dir: order[:dir] }
    { search_value: search_value, order_by_column: order_by_column }
  end

  def sortable_columns
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

    if sortable_columns[column_id - 1] == 'assigned'
      return records if @my_module && @params[:assigned] == 'assigned'
      if @my_module
        # Depending on the sort, order nulls first or
        # nulls last on repository_cells association
        return records.joins(
          "LEFT OUTER JOIN my_module_repository_rows ON
          (repository_rows.id =
            my_module_repository_rows.repository_row_id
          AND (my_module_repository_rows.my_module_id =
            #{@my_module.id}
          OR my_module_repository_rows.id IS NULL))"
        ).order(
          "my_module_repository_rows.id NULLS
           #{sort_null_direction(dir)}"
        )
      else
        return sort_assigned_records(records, dir)
      end
    elsif sortable_columns[column_id - 1] == 'repository_cell.value'
      id = @mappings.key(column_id.to_s)
      type = RepositoryColumn.find_by_id(id)
      return records unless type
      return select_type(type.data_type, records, id, dir)
    elsif sortable_columns[column_id - 1] == 'users.full_name'
      return records.joins(:created_by).order("users.full_name #{dir}")
    else
      return records.order(
        "#{sortable_columns[column_id - 1]} #{dir}"
      )
    end
  end

  def sort_assigned_records(records, direction)
    assigned = records.joins(:my_module_repository_rows)
                      .distinct
                      .pluck(:id)
    unassigned = records.where.not(id: assigned).pluck(:id)
    if direction == 'ASC'
      ids = assigned + unassigned
    elsif direction == 'DESC'
      ids = unassigned + assigned
    end

    order_by_index = ActiveRecord::Base.send(
      :sanitize_sql_array,
      ["position((',' || repository_rows.id || ',') in ?)",
       ids.join(',') + ',']
    )
    records.order(order_by_index)
  end

  def select_type(type, records, id, dir)
    case type
    when 'RepositoryTextValue'
      filter_by_text_value(records, id, dir)
    when 'RepositoryListValue'
      filter_by_list_value(records, id, dir)
    when 'RepositoryAssetValue'
      filter_by_asset_value(records, id, dir)
    else
      records
    end
  end

  def sort_null_direction(val)
    val == 'ASC' ? 'LAST' : 'FIRST'
  end

  def filter_by_asset_value(records, id, dir)
    records.joins(
      "LEFT OUTER JOIN (SELECT repository_cells.repository_row_id,
        assets.file_file_name AS value
      FROM repository_cells
      INNER JOIN repository_asset_values
      ON repository_asset_values.id = repository_cells.value_id
      INNER JOIN assets
      ON repository_asset_values.asset_id = assets.id
      WHERE repository_cells.repository_column_id = #{id}) AS values
      ON values.repository_row_id = repository_rows.id"
    ).order("values.value #{dir}")
  end

  def filter_by_text_value(records, id, dir)
    records.joins(
      "LEFT OUTER JOIN (SELECT repository_cells.repository_row_id,
        repository_text_values.data AS value
      FROM repository_cells
      INNER JOIN repository_text_values
      ON repository_text_values.id = repository_cells.value_id
      WHERE repository_cells.repository_column_id = #{id}) AS values
      ON values.repository_row_id = repository_rows.id"
    ).order("values.value #{dir}")
  end

  def filter_by_list_value(records, id, dir)
    records.joins(
      "LEFT OUTER JOIN (SELECT repository_cells.repository_row_id,
        repository_list_items.data AS value
      FROM repository_cells
      INNER JOIN repository_list_values
      ON repository_list_values.id = repository_cells.value_id
      INNER JOIN repository_list_items
      ON repository_list_values.repository_list_item_id =
      repository_list_items.id
      WHERE repository_cells.repository_column_id = #{id}) AS values
      ON values.repository_row_id = repository_rows.id"
    ).order("values.value #{dir}")
  end
end
