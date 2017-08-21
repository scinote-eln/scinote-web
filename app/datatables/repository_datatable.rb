require 'active_record'

class RepositoryDatatable < CustomDatatable
  include ActionView::Helpers::TextHelper
  include SamplesHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include ActiveRecord::Sanitization::ClassMethods

  ASSIGNED_SORT_COL = 'assigned'.freeze

  REPOSITORY_TABLE_DEFAULT_STATE = {
    'time' => 0,
    'start' => 0,
    'length' => 5,
    'order' => [[2, 'desc']],
    'search' => { 'search' => '',
                  'smart' => true,
                  'regex' => false,
                  'caseInsensitive' => true },
    'columns' => [],
    'assigned' => 'assigned',
    'ColReorder' => [*0..4]
  }
  5.times do
    REPOSITORY_TABLE_DEFAULT_STATE['columns'] << {
      'visible' => true,
      'search' => { 'search' => '',
                    'smart' => true,
                    'regex' => false,
                    'caseInsensitive' => true }
    }
  end
  REPOSITORY_TABLE_DEFAULT_STATE.freeze

  def initialize(view,
                 repository,
                 my_module = nil,
                 user = nil)
    super(view)
    @repository = repository
    @team = repository.team
    @my_module = my_module
    @user = user
  end

  # Define sortable columns, so 1st column will be sorted by attribute
  # in sortable_columns[0]
  def sortable_columns
    sort_array = [
      ASSIGNED_SORT_COL,
      'RepositoryRow.name',
      'RepositoryRow.created_at',
      'User.full_name'
    ]

    sort_array.push(*repository_columns_sort_by)
    @sortable_columns = sort_array
  end

  # Define attributes on which we perform search
  def searchable_columns
    search_array = [
      'RepositoryRow.name',
      'RepositoryRow.created_at',
      'User.full_name'
    ]

    # search_array.push(*repository_columns_sort_by)
    @searchable_columns ||= filter_search_array search_array
  end

  private

  # filters the search array by checking if the the column is visible
  def filter_search_array(input_array)
    param_index = 2
    filtered_array = []
    input_array.each do |col|
      next if columns_params.to_a[param_index].nil?
      params_col =
        columns_params.to_a.find { |v| v[1]['data'] == param_index.to_s }
      filtered_array.push(col) unless params_col[1]['searchable'] == 'false'
      param_index += 1
    end
    filtered_array
  end

  # Get array of columns to sort by (for custom columns)
  def repository_columns_sort_by
    array = []
    @repository.repository_columns.count.times do
      array << 'RepositoryCell.value'
    end
    array
  end

  # Returns json of current repository rows (already paginated)
  def data
    records.map do |record|
      row = {
        'DT_RowId': record.id,
        '1': assigned_row(record),
        '2': escape_input(record.name),
        '3': I18n.l(record.created_at, format: :full),
        '4': escape_input(record.created_by.full_name),
        'recordEditUrl':
          Rails.application.routes.url_helpers
               .edit_repository_repository_row_path(@repository,
                                                    record.id),
        'recordUpdateUrl':
          Rails.application.routes.url_helpers
               .repository_repository_row_path(@repository, record.id)
      }

      # Add custom columns
      record.repository_cells.each do |cell|
        row[@columns_mappings[cell.repository_column.id]] =
          custom_auto_link(
            display_tooltip(cell.value.data,
                            Constants::NAME_MAX_LENGTH),
            simple_format: true,
            team: @team
          )
      end
      row
    end
  end

  def assigned_row(record)
    if @assigned_rows && @assigned_rows.include?(record)
      "<span class='circle'>&nbsp;</span>"
    else
      "<span class='circle disabled'>&nbsp;</span>"
    end
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    repository_rows = RepositoryRow
                      .preload(
                        :repository_columns,
                        :created_by,
                        repository_cells: :value
                      )
                      .joins(:created_by)
                      .where(repository: @repository)

    # Make mappings of custom columns, so we have same id for every column
    i = 5
    @columns_mappings = {}
    @repository.repository_columns.order(:id).each do |column|
      @columns_mappings[column.id] = i.to_s
      i += 1
    end

    if @my_module
      @assigned_rows = @my_module.repository_rows
                                 .preload(
                                   :repository_columns,
                                   :created_by,
                                   repository_cells: :value
                                 )
                                 .joins(:created_by)
                                 .where(repository: @repository)
      return @assigned_rows if dt_params[:assigned] == 'assigned'
    else
      @assigned_rows = repository_rows.joins(
        'INNER JOIN my_module_repository_rows ON
        (repository_rows.id = my_module_repository_rows.repository_row_id)'
      )
    end

    repository_rows
  end

  # Override default behaviour
  # Don't filter and paginate records when sorting by custom column - everything
  # is done in sort_records method - you might ask why, well if you want the
  # number of samples/all samples it's dependant upon sort_record query
  def fetch_records
    records = get_raw_records
    records = filter_records(records) if dt_params[:search].present? &&
                                         dt_params[:search][:value].present?
    records = sort_records(records) if order_params.present?
    records = paginate_records(records) unless dt_params[:length].present? &&
                                               dt_params[:length] == '-1'
    escape_special_chars
    records
  end

  # Overriden to make it work for custom columns, because they are polymorphic
  # NOTE: Function assumes the provided records/rows are only from the current
  # repository!
  def filter_records(repo_rows)
    search_val = dt_params[:search][:value]
    filtered_rows = repo_rows.find_by_sql(
      "SELECT DISTINCT repository_rows.*
       FROM repository_rows
       INNER JOIN (
         SELECT users.*
         FROM users
       ) AS users
       ON users.id = repository_rows.created_by_id
       LEFT OUTER JOIN (
         SELECT repository_cells.repository_row_id,
                repository_text_values.data AS text_value,
                to_char(repository_date_values.data, 'DD.MM.YYYY HH24:MI')
                AS date_value
         FROM repository_cells
         INNER JOIN repository_text_values
         ON repository_text_values.id = repository_cells.value_id
         FULL OUTER JOIN repository_date_values
         ON repository_date_values.id = repository_cells.value_id
       ) AS values
       ON values.repository_row_id = repository_rows.id
       WHERE repository_rows.repository_id = #{@repository.id}
             AND (repository_rows.name ILIKE '%#{search_val}%'
                  OR to_char(repository_rows.created_at, 'DD.MM.YYYY HH24:MI')
                     ILIKE '%#{search_val}%'
                  OR users.full_name ILIKE '%#{search_val}%'
                  OR text_value ILIKE '%#{search_val}%'
                  OR date_value ILIKE '%#{search_val}%')"
    )
    repo_rows.where(id: filtered_rows)
  end

  # Override default sort method if needed
  def sort_records(records)
    if params[:order].present? && params[:order].length == 1
      if sort_column(params[:order].values[0]) == ASSIGNED_SORT_COL
        # If "assigned" column is sorted when viewing assigned items
        return records if @my_module && params[:assigned] == 'assigned'
        # If "assigned" column is sorted
        direction = sort_null_direction(params[:order].values[0])
        if @my_module
          # Depending on the sort, order nulls first or
          # nulls last on repository_cells association
          records.joins(
            "LEFT OUTER JOIN my_module_repository_rows ON
            (repository_rows.id = my_module_repository_rows.repository_row_id
            AND (my_module_repository_rows.my_module_id = #{@my_module.id} OR
                              my_module_repository_rows.id IS NULL))"
          ).order("my_module_repository_rows.id NULLS #{direction}")
        else
          sort_assigned_records(records, params[:order].values[0]['dir'])
        end
      elsif sorting_by_custom_column
        ci = sortable_displayed_columns[
          params[:order].values[0][:column].to_i - 1
        ]
        column_id = @columns_mappings.key((ci.to_i + 1).to_s)
        dir = sort_direction(params[:order].values[0])

        records.joins(
          "LEFT OUTER JOIN my_module_repository_rows ON
          (repository_rows.id = my_module_repository_rows.repository_row_id
          AND (my_module_repository_rows.my_module_id = #{@my_module.id} OR
                            my_module_repository_rows.id IS NULL))"
        ).order("my_module_repository_rows.id NULLS #{direction}")
      else
        records.joins(
          'LEFT OUTER JOIN my_module_repository_rows ON
          (repository_rows.id = my_module_repository_rows.repository_row_id)'
        ).order("my_module_repository_rows.id NULLS #{direction}")
      end
    elsif sorting_by_custom_column
      ci = sortable_displayed_columns[order_params[:column].to_i - 1]
      column_id = @columns_mappings.key((ci.to_i + 1).to_s)
      dir = sort_direction(order_params)

      records.joins(
        "LEFT OUTER JOIN (SELECT repository_cells.repository_row_id,
          repository_text_values.data AS value FROM repository_cells
			  INNER JOIN repository_text_values
			  ON repository_text_values.id = repository_cells.value_id
			  WHERE repository_cells.repository_column_id = #{column_id}) AS values
        ON values.repository_row_id = repository_rows.id"
      ).order("values.value #{dir}")
    else
      super(records)
    end
  end

  def sort_null_direction(item)
    val = sort_direction(item)
    val == 'ASC' ? 'LAST' : 'FIRST'
  end

  def inverse_sort_direction(item)
    val = sort_direction(item)
    val == 'ASC' ? 'DESC' : 'ASC'
  end

  def sorting_by_custom_column
    sort_column(order_params) == 'repository_cells.value'
  end

  # Escapes special characters in search query
  def escape_special_chars
    if dt_params[:search].present?
      dt_params[:search][:value] = ActiveRecord::Base
                                   .__send__(:sanitize_sql_like,
                                             dt_params[:search][:value])
    end
  end

  def new_sort_column(item)
    coli = item[:column].to_i - 1
    model, column = sortable_columns[sortable_displayed_columns[coli].to_i]
                    .split('.')

    return model if model == ASSIGNED_SORT_COL
    [model.constantize.table_name, column].join('.')
  end

  def generate_sortable_displayed_columns
    sort_order = RepositoryTableState.load_state(@user, @repository)
                                     .first['ColReorder']
    sort_order.shift
    sort_order.map! { |i| (i.to_i - 1).to_s }

    @sortable_displayed_columns = sort_order
  end

  def sort_assigned_records(records, direction)
    assigned = records.joins(:my_module_repository_rows).distinct.pluck(:id)
    unassigned = records.where.not(id: assigned).pluck(:id)
    if direction == 'asc'
      ids = assigned + unassigned
    elsif direction == 'desc'
      ids = unassigned + assigned
    end

    order_by_index = ActiveRecord::Base.send(
      :sanitize_sql_array,
      ["position((',' || repository_rows.id || ',') in ?)",
      ids.join(',') + ',']
    )
    records.order(order_by_index)
  end
end
