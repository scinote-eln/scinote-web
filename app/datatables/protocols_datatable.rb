class ProtocolsDatatable < CustomDatatable
  # Needed for sanitize_sql_like method
  include ActiveRecord::Sanitization::ClassMethods
  include InputSanitizeHelper

  def_delegator :@view, :can_read_protocol_in_repository?
  def_delegator :@view, :can_manage_protocol_in_repository?
  def_delegator :@view, :edit_protocol_path
  def_delegator :@view, :can_restore_protocol_in_repository?
  def_delegator :@view, :can_clone_protocol_in_repository?
  def_delegator :@view, :clone_protocol_path
  def_delegator :@view, :linked_children_protocol_path
  def_delegator :@view, :preview_protocol_path

  def initialize(view, team, type, user)
    super(view)
    @team = team
    # :public, :private or :archive
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

  private

  # Returns json of current protocols (already paginated)
  def data
    result_data = []
    records.each do |record|
      protocol = Protocol.find(record.id)
      result_data << {
        'DT_RowId': record.id,
        'DT_CanEdit': can_manage_protocol_in_repository?(protocol),
        'DT_EditUrl': if can_manage_protocol_in_repository?(protocol)
                        edit_protocol_path(protocol,
                                           team: @team,
                                           type: @type)
                      end,
        'DT_CanClone': can_clone_protocol_in_repository?(protocol),
        'DT_CloneUrl': if can_clone_protocol_in_repository?(protocol)
                         clone_protocol_path(protocol,
                                             team: @team,
                                             type: @type)
                       end,
        'DT_CanMakePrivate': can_manage_protocol_in_repository?(protocol),
        'DT_CanPublish': can_manage_protocol_in_repository?(protocol),
        'DT_CanArchive': can_manage_protocol_in_repository?(protocol),
        'DT_CanRestore': can_restore_protocol_in_repository?(protocol),
        'DT_CanExport': can_read_protocol_in_repository?(protocol),
        '1': if protocol.in_repository_archived?
               escape_input(record.name)
             else
               name_html(record)
             end,
        '2': keywords_html(record),
        '3': modules_html(record),
        '4': escape_input(record.full_username_str),
        '5': timestamp_column_html(record),
        '6': I18n.l(record.updated_at, format: :full)
      }
    end
    result_data
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
    elsif @type == :private
      records =
        records
        .joins('LEFT OUTER JOIN users ON users.id = protocols.added_by_id')
        .where('protocols.protocol_type = ?',
               Protocol.protocol_types[:in_repository_private])
        .where(added_by: @user)
    else
      records =
        records
        .joins('LEFT OUTER JOIN users ON users.id = protocols.archived_by_id')
        .where('protocols.protocol_type = ?',
               Protocol.protocol_types[:in_repository_archived])
        .where(added_by: @user)
    end

    records.group('"protocols"."id"')
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
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
      '"protocols"."published_on"',
      '"protocols"."archived_on"'
    )
  end

  # Various helper methods

  def timestamp_db_column
    if @type == :public
      "Protocol.published_on"
    elsif @type == :private
      "Protocol.created_at"
    else
      "Protocol.archived_on"
    end
  end

  def name_html(record)
    "<a href='#' data-action='protocol-preview'" \
      "data-url='#{preview_protocol_path(record)}'>" \
      "#{escape_input(record.name)}" \
      "</a>"
  end

  def keywords_html(record)
    if !record.protocol_keywords_str || record.protocol_keywords_str.empty?
      "<i>#{I18n.t("protocols.no_keywords")}</i>"
    else
      kws = record.protocol_keywords_str.split(", ")
      res = []
      kws.sort_by{ |word| word.downcase }.each do |kw|
        sanitized_kw = sanitize_input(kw)
        res << "<a href='#' data-action='filter' " \
          "data-param='#{sanitized_kw}'>#{sanitized_kw}</a>"
      end
      res.join(', ')
    end
  end

  def modules_html(record)
    "<a href='#' data-action='load-linked-children' class='help_tooltips' " \
    "data-tooltiplink='" +
      I18n.t('tooltips.link.protocol.num_linked') +
      "' data-tooltipcontent='" +
      I18n.t('tooltips.text.protocol.num_linked') +
      "' data-url='#{linked_children_protocol_path(record)}'>" \
      "#{record.nr_of_linked_children}"  \
      "</a>"
  end

  def timestamp_column_html(record)
    if @type == :public
      I18n.l(record.published_on, format: :full)
    elsif @type == :private
      I18n.l(record.created_at, format: :full)
    else
      I18n.l(record.archived_on, format: :full)
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
