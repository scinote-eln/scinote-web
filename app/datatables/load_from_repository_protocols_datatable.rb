class LoadFromRepositoryProtocolsDatatable < CustomDatatable
  # Needed for sanitize_sql_like method
  include ActiveRecord::Sanitization::ClassMethods
  include InputSanitizeHelper

  def initialize(view, team, user)
    super(view)
    @team = team
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      'Protocol.name',
      'nr_of_versions',
      'Protocol.id',
      'protocol_keywords_str',
      'full_username_str',
      'Protocol.published_on'
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      'Protocol.name',
      'Protocol.id',
      'Protocol.published_on'
    ]
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
        '0': escape_input(record.name),
        '1': record.nr_of_versions,
        '2': record.code,
        '3': keywords_html(record),
        '4': escape_input(record.full_username_str),
        '5': I18n.l(record.published_on, format: :full)
      }
    end
  end

  def get_raw_records_base
    records =
      Protocol
      .where(team: @team)
      .where(protocols: { protocol_type: Protocol.protocol_types[:in_repository_published_original] })
      .joins("LEFT OUTER JOIN protocols protocol_versions "\
             "ON protocol_versions.protocol_type = #{Protocol.protocol_types[:in_repository_published_version]} "\
             "AND protocol_versions.parent_id = protocols.id")
      .joins('LEFT OUTER JOIN "protocol_protocol_keywords" '\
             'ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
      .joins('LEFT OUTER JOIN "protocol_keywords"'\
             'ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')
      .joins('LEFT OUTER JOIN users ON users.id = protocols.published_by_id').active

    records.group('"protocols"."id"')
  end

  # OVERRIDE - query database for records (this will be
  # later paginated and filtered) after that "data" function
  # will return json
  def get_raw_records
    get_raw_records_base
      .select(
        '"protocols".*',
        'STRING_AGG("protocol_keywords"."name", \', \') AS "protocol_keywords_str"',
        'COUNT("protocol_versions"."id") + 1 AS "nr_of_versions"',
        'MAX("users"."full_name") AS "full_username_str"'
      )
  end

  # Various helper methods

  def keywords_html(record)
    if record.protocol_keywords_str.blank?
      "<i>#{I18n.t('protocols.no_keywords')}</i>"
    else
      kws = record.protocol_keywords_str.split(', ')
      res = []
      kws.sort_by(&:downcase).each do |kw|
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
      ' OR ' +
      ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [::Arel::Nodes::SqlLiteral.new("max(\"users\".\"full_name\") AS #{typecast}")]
      ).matches("%#{sanitize_sql_like(search_val)}%").to_sql +
      ' OR ' +
      ::Arel::Nodes::NamedFunction.new(
        'CAST',
        [::Arel::Nodes::SqlLiteral.new("COUNT(\"protocol_versions\".\"id\") + 1 AS #{typecast}")]
      ).matches("%#{sanitize_sql_like(search_val)}%").to_sql
    ).select(:id)

    # Call parent function
    criteria = super(query)

    # Aight, now append another or
    criteria.or(Protocol.arel_table[:id].in(records_having.arel))
  end
end
