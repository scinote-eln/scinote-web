require 'active_record'

class RepositoryDatatable < AjaxDatatablesRails::Base
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
      next if params[:columns].to_a[param_index].nil?
      params_col =
        params[:columns].to_a.find { |v| v[1]['data'] == param_index.to_s }
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
    @repository.repository_columns.each do |column|
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
      return @assigned_rows if params[:assigned] == 'assigned'
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
    records = filter_records(records) if params[:search].present?
    records = sort_records(records) if params[:order].present?
    records = paginate_records(records) unless params[:length].present? &&
                                               params[:length] == '-1'
    escape_special_chars
    records
  end

  # Overriden to make it work for custom columns, because they are polymorphic
  # NOTE: Function assumes the provided records/rows are only from the current
  # repository!
  def filter_records(repo_rows)
    return repo_rows unless params[:search].present? &&
                            params[:search][:value].present?
    search_val = params[:search][:value]

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
          records.joins(
            'LEFT OUTER JOIN my_module_repository_rows ON
            (repository_rows.id = my_module_repository_rows.repository_row_id)'
          ).order("my_module_repository_rows.id NULLS #{direction}")
        end
      elsif sorting_by_custom_column
        # Check if have to filter records first
        # if params[:search].present? && params[:search][:value].present?
        #   # Couldn't force ActiveRecord to yield the same query as below because
        #   # Rails apparently forgets to join stuff in subqueries -
        #   # #justrailsthings
        #   conditions = build_conditions_for(params[:search][:value])
        #
        #   filter_query = %(SELECT "samples"."id" FROM "samples"
        #     LEFT OUTER JOIN "sample_custom_fields" ON
        #     "sample_custom_fields"."sample_id" = "samples"."id"
        #     LEFT OUTER JOIN "users" ON "users"."id" = "repository_row"."user_id"
        #     WHERE "samples"."team_id" = #{@team.id} AND #{conditions.to_sql})
        #
        #   records = records.where("samples.id IN (#{filter_query})")
        # end

        ci = sortable_displayed_columns[
          params[:order].values[0][:column].to_i - 1
        ]
        column_id = @columns_mappings.key((ci.to_i + 1).to_s)
        dir = sort_direction(params[:order].values[0])

        # Because repository records can have multiple custom cells,
        # we first group them by samples.id and inside that group we sort them by column_id. Because
        # we sort them ASC, sorted columns will be on top. Distinct then only
        # takes the first row and cuts the rest of every group and voila we have
        # 1 row for every sample, which are not sorted yet ...
        # records = records.select('DISTINCT ON (repository_rows.id) *')
        # .order("repository_rows.id, CASE WHEN repository_cells.repository_column_id = #{column_id} THEN 1 ELSE 2 END ASC")

        # ... this little gem (pun intended) then takes the records query, sorts it again
        # and paginates it. sq.t0_* are determined empirically and are crucial -
        # imagine A -> B -> C transitive relation but where A and C are the
        # same. Useless right? But not when you acknowledge that find_by_sql
        # method does some funky stuff when your query spans multiple queries -
        # Sample object might have id from SampleType, name from
        # User ... chaos ensues basically. If something changes in db this might
        # change.
        # formated_date = (I18n.t 'time.formats.datatables_date').gsub!(/^\"|\"?$/, '')
        # Sample.find_by_sql("SELECT sq.t0_r0 as id, sq.t0_r1 as name, to_char( sq.t0_r4, '#{ formated_date }' ) as created_at, sq.t0_r5, s, sq.t0_r2 as user_id, sq.custom_field_id FROM (#{records.to_sql})
        #                              as sq ORDER BY CASE WHEN sq.custom_field_id = #{column_id} THEN 1 ELSE 2 END #{dir}, sq.value #{dir}
        #                              LIMIT #{per_page} OFFSET #{offset}")

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
    else
      super(records)
    end
  end

  # A hack that overrides the new_search_contition method default behavior of the ajax-datatables-rails gem
  # now the method checks if the column is the created_at and generate a custom SQL to parse
  # it back to the caller method
  # def new_search_condition(column, value)
  #   model, column = column.split('.')
  #   model = model.constantize
  #   formated_date = (I18n.t 'time.formats.datatables_date').gsub!(/^\"|\"?$/, '')
  #   if model == SampleCustomField
  #     # Find visible (searchable) custom field IDs, and only perform filter
  #     # on those custom fields
  #     searchable_cfs = params[:columns].select do |_, v|
  #       v['searchable'] == 'true' && @cf_mappings.values.include?(v['data'])
  #     end
  #     cfmi = @cf_mappings.invert
  #     cf_ids = searchable_cfs.map { |_, v| cfmi[v['data']] }
  #
  #     # Do an ILIKE on 'value', as well as make sure to only include
  #     # custom fields that have 'custom_field_id' among visible custom fields
  #     casted_column = ::Arel::Nodes::NamedFunction.new(
  #       'CAST',
  #       [model.arel_table[column.to_sym].as(typecast)]
  #     )
  #     casted_column = casted_column.matches("%#{value}%")
  #     casted_column = casted_column.and(
  #       model.arel_table['custom_field_id'].in(cf_ids)
  #     )
  #     casted_column
  #   elsif column == 'created_at'
  #     casted_column = ::Arel::Nodes::NamedFunction.new('CAST',
  #                       [ Arel.sql("to_char( samples.created_at, '#{ formated_date }' ) AS VARCHAR") ] )
  #     casted_column.matches("%#{sanitize_sql_like(value)}%")
  #   else
  #     casted_column = ::Arel::Nodes::NamedFunction.new('CAST',
  #                       [model.arel_table[column.to_sym].as(typecast)])
  #     casted_column.matches("%#{sanitize_sql_like(value)}%")
  #   end
  # end

  def sort_null_direction(item)
    val = sort_direction(item)
    val == 'ASC' ? 'LAST' : 'FIRST'
  end

  def inverse_sort_direction(item)
    val = sort_direction(item)
    val == 'ASC' ? 'DESC' : 'ASC'
  end

  def sorting_by_custom_column
    sort_column(params[:order].values[0]) == 'repository_cells.value'
  end

  # Escapes special characters in search query
  def escape_special_chars
    if params[:search].present?
      params[:search][:value] = ActiveRecord::Base
                                .__send__(:sanitize_sql_like,
                                          params[:search][:value])
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
end
