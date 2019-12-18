# frozen_string_literal: true

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
    search_value = build_conditions(@params)[:search_value]
    order_obj = build_conditions(@params)[:order_by_column]

    repository_rows = fetch_rows(search_value)
    assigned_rows = repository_rows.joins(:my_module_repository_rows)
    if @my_module
      assigned_rows = assigned_rows
                      .where(my_module_repository_rows: {
                               my_module_id: @my_module
                             })
      repository_rows = assigned_rows if @params[:assigned] == 'assigned'
    end

    @assigned_rows = assigned_rows
    @repository_rows = sort_rows(order_obj, repository_rows)
  end

  def fetch_rows(search_value)
    repository_rows = @repository.repository_rows
                                 .left_outer_joins(:created_by)

    if search_value.present?
      includes_json = { repository_cells: Extends::REPOSITORY_SEARCH_INCLUDES }
      searchable_attributes = ['repository_rows.name',
                               'users.full_name',
                               'repository_rows.id'] +
                              Extends::REPOSITORY_EXTRA_SEARCH_ATTR

      # Using distinct raises error when combined with sort on a custom column
      repository_row_ids = repository_rows
                           .left_outer_joins(includes_json)
                           .where_attributes_like(searchable_attributes,
                                                  search_value)
                           .pluck(:id)
                           .uniq
      repository_rows = RepositoryRow.left_outer_joins(:created_by)
                                     .where(id: repository_row_ids)
    end

    repository_rows
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
      sorting_column = RepositoryColumn.find_by(id: id)
      return records unless sorting_column

      sorting_data_type = sorting_column.data_type.constantize

      cells = RepositoryCell.joins(sorting_data_type::SORTABLE_VALUE_INCLUDE)
                            .where('repository_cells.repository_column_id': sorting_column.id)
                            .select("DISTINCT ON (repository_cells.repository_row_id) repository_row_id,
                                    #{sorting_data_type::SORTABLE_COLUMN_NAME} AS value")

      records.joins("LEFT OUTER JOIN (#{cells.to_sql}) AS values ON values.repository_row_id = repository_rows.id")
             .order("values.value #{dir}")
    elsif sortable_columns[column_id - 1] == 'users.full_name'
      # We don't need join user table, because it already joined in fetch_row method
      return records.order("users.full_name #{dir}")
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

  def sort_null_direction(val)
    val == 'ASC' ? 'LAST' : 'FIRST'
  end

  def filter_by_asset_value(records, id, dir)
    records.joins(
      "LEFT OUTER JOIN (SELECT repository_cells.repository_row_id,
        active_storage_blobs.filename AS value
      FROM repository_cells
      INNER JOIN repository_asset_values
      ON repository_asset_values.id = repository_cells.value_id
      INNER JOIN assets
      ON repository_asset_values.asset_id = assets.id
      INNER JOIN active_storage_attachments
      ON active_storage_attachments.record_id = assets.id
         AND active_storage_attachments.record_type = 'Asset'
         AND active_storage_attachments.name = 'file'
      INNER JOIN active_storage_blobs
      ON active_storage_blobs.id = active_storage_attachments.blob_id
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
