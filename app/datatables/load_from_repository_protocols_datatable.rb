class LoadFromRepositoryProtocolsDatatable < CustomDatatable
  # Needed for sanitize_sql_like method
  include ActiveRecord::Sanitization::ClassMethods
  include InputSanitizeHelper

  def initialize(view, team, type, user)
    super(view)
    @team = team
    # :public or :private
    @type = type
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      "Protocol.name",
      "protocol_keywords_str",
      "Protocol.nr_of_linked_children",
      "full_username_str",
      timestamp_db_column,
      "Protocol.updated_at"
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      "Protocol.name",
      timestamp_db_column,
      "Protocol.updated_at"
    ]
  end

  # A hack that overrides the new_search_contition method default behavior of the ajax-datatables-rails gem
  # now the method checks if the column is the created_at or updated_at and generate a custom SQL to parse
  # it back to the caller method
  def new_search_condition(column, value)
    model, column = column.split('.')
    model = model.constantize
    case column
    when 'published_on'
      casted_column = ::Arel::Nodes::NamedFunction.new('CAST',
                        [ Arel.sql("to_char( protocols.created_at, '#{ formated_date }' ) AS VARCHAR") ] )
    when 'updated_at'
      casted_column = ::Arel::Nodes::NamedFunction.new('CAST',
                        [ Arel.sql("to_char( protocols.updated_at, '#{ formated_date }' ) AS VARCHAR") ] )
    else
      casted_column = ::Arel::Nodes::NamedFunction.new('CAST',
                        [model.arel_table[column.to_sym].as(typecast)])
    end
    casted_column.matches("%#{value}%")
  end

  # This hack is needed to display a correct amount of
  # searched entries (needed for pagination).
  # This is needed because of usage of GROUP operator in SQL.
  # See https://github.com/antillas21/ajax-datatables-rails/issues/112
  def as_json(options = {})
    {
      draw: dt_params[:draw].to_i,
      recordsTotal: get_raw_records.length,
      recordsFiltered: filter_records(get_raw_records).length,
      data: data
    }
  end

  private

  # Returns json of current protocols (already paginated)
  def data
    records.map do |record|
      {
        'DT_RowId': record.id,
        '1': escape_input(record.name),
        '2': keywords_html(record),
        '3': record.nr_of_linked_children,
        '4': escape_input(record.full_username_str),
        '5': timestamp_column_html(record),
        '6': I18n.l(record.updated_at, format: :full)
      }
    end
  end

  def get_raw_records_base
    records =
      Protocol
      .where(team: @team)
      .joins('LEFT OUTER JOIN "protocol_protocol_keywords" ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
      .joins('LEFT OUTER JOIN "protocol_keywords" ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')

    if @type == :public
      records =
        records
        .joins('LEFT OUTER JOIN users ON users.id = protocols.added_by_id')
        .where('protocols.protocol_type = ?',
               Protocol.protocol_types[:in_repository_public])
    else
      records =
        records
        .joins('LEFT OUTER JOIN users ON users.id = protocols.added_by_id')
        .where('protocols.protocol_type = ?',
               Protocol.protocol_types[:in_repository_private])
        .where(added_by: @user)
    end

    records.group('"protocols"."id"')
  end

  # OVERRIDE - query database for records (this will be
  # later paginated and filtered) after that "data" function
  # will return json
  def get_raw_records
    get_raw_records_base
    .select(
      '"protocols"."id"',
      '"protocols"."name"',
      '"protocols"."protocol_type"',
      'string_agg("protocol_keywords"."name", \', \') AS "protocol_keywords_str"',
      '"protocols"."nr_of_linked_children"',
      'max("users"."full_name") AS "full_username_str"', # "Hack" to get single username
      '"protocols"."created_at"',
      '"protocols"."updated_at"',
      '"protocols"."published_on"'
    )
  end

  # Various helper methods

  def timestamp_db_column
    if @type == :public
      "Protocol.published_on"
    else
      "Protocol.created_at"
    end
  end

  def keywords_html(record)
    if !record.protocol_keywords_str || record.protocol_keywords_str.empty?
      "<i>#{I18n.t("protocols.no_keywords")}</i>"
    else
      kws = record.protocol_keywords_str.split(", ")
      res = []
      kws.sort_by{ |word| word.downcase }.each do |kw|
        res << "<a href='#' data-action='filter' data-param='#{kw}'>#{kw}</a>"
      end
      sanitize_input(res.join(', '))
    end
  end

  def timestamp_column_html(record)
    if @type == :public
      I18n.l(record.published_on, format: :full)
    else
      I18n.l(record.created_at, format: :full)
    end
  end

  # OVERRIDE - This is only called when filtering results;
  # when using GROUP BY function, SQL cannot perform a WHERE
  # clause on aggregated columns (protocol keywords & users' full_name), but
  # since we want those 2 columns to be searchable/filterable, we do an "inner"
  # query where we select only protocol IDs which are filtered by those 2 columns
  # using HAVING keyword (which is the correct way to filter aggregated columns).
  # Another OR is then appended to the WHERE clause, checking if protocol is inside
  # this list of IDs.
  def build_conditions_for(query)
    # Inner query to retrieve list of protocol IDs where concatenated
    # protocol keywords string, or user's full_name contains searched query
    search_val = dt_params[:search][:value]
    records_having = get_raw_records_base.having(
      ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [::Arel::Nodes::SqlLiteral.new("string_agg(\"protocol_keywords\".\"name\", ' ') AS #{typecast}")]
      ).matches("%#{sanitize_sql_like(search_val)}%").to_sql +
      " OR " +
      ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [::Arel::Nodes::SqlLiteral.new("max(\"users\".\"full_name\") AS #{typecast}")]
      ).matches("%#{sanitize_sql_like(search_val)}%").to_sql
    ).select(:id)

    # Call parent function
    criteria = super(query)

    # Aight, now append another or
    criteria = criteria.or(Protocol.arel_table[:id].in(records_having.arel))
    criteria
  end
end
