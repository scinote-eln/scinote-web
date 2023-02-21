class ProtocolsDatatable < CustomDatatable
  # Needed for sanitize_sql_like method
  include ActiveRecord::Sanitization::ClassMethods
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  def_delegator :@view, :can_read_protocol_in_repository?
  def_delegator :@view, :can_manage_protocol_in_repository?
  def_delegator :@view, :edit_protocol_path
  def_delegator :@view, :can_restore_protocol_in_repository?
  def_delegator :@view, :can_clone_protocol_in_repository?
  def_delegator :@view, :clone_protocol_path
  def_delegator :@view, :linked_children_protocol_path
  def_delegator :@view, :protocol_path

  def initialize(view, team, type, user)
    super(view)
    @team = team
    # :public, :private or :archive
    @type = type
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      'Protocol.name',
      'Protocol.id',
      'nr_of_versions',
      'protocol_keywords_str',
      'Protocol.nr_of_linked_children',
      'nr_of_assigned_users',
      'full_username_str',
      'Protocol.archived_on',
      'Protocol.published_on',
      'Protocol.updated_at'
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      "Protocol.name",
      'Protocol.archived_on',
      'Protocol.published_on',
      "Protocol.#{Protocol::PREFIXED_ID_SQL}",
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
    model, column = column.split('.', 2)
    model = model.constantize
    case column
    when Protocol::PREFIXED_ID_SQL
      casted_column = ::Arel::Nodes::SqlLiteral.new(Protocol::PREFIXED_ID_SQL)
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
    records.map do |record|
      {
        DT_RowId: record.id,
        DT_RowAttr: {
          'data-permissions-url': permissions_protocol_path(record)
        },
        DT_CanClone: can_clone_protocol_in_repository?(record),
        DT_CloneUrl: if can_clone_protocol_in_repository?(record)
                       clone_protocol_path(record, team: @team, type: @type)
                     end,
        DT_RowAttr: {
          'data-permissions-url': permissions_protocol_path(record)
        },
        '1': name_html(record),
        '2': record.code,
        '3': versions_html(record),
        '4': keywords_html(record),
        '5': modules_html(record),
        '6': access_html(record),
        '7': escape_input(record.full_username_str),
        '8': I18n.l(record.published_on || record.created_at, format: :full),
        '9': I18n.l(record.updated_at, format: :full),
        '10': escape_input(record.archived_full_username_str),
        '11': (I18n.l(record.archived_on, format: :full) if record.archived_on)
      }
    end
  end

  def filter_protocols_records(records)
    if params[:name_and_keywords].present?
      records = records.where_attributes_like(['protocols.name', 'protocol_keywords.name'], params[:name_and_keywords])
    end

    if params[:published_on_from].present?
      records = records.where('protocols.published_on > ?', params[:published_on_from])
    end
    records = records.where('protocols.published_on < ?', params[:published_on_to]) if params[:published_on_to].present?
    records = records.where('protocols.updated_at > ?', params[:modified_on_from]) if params[:modified_on_from].present?
    records = records.where('protocols.updated_at < ?', params[:modified_on_to]) if params[:modified_on_to].present?
    records = records.where(protocols: { published_by_id: params[:published_by] }) if params[:published_by].present?

    if params[:members].present?
      records = records.joins(:user_assignments).where(user_assignments: { user_id: params[:members] })
    end

    if params[:archived_on_from].present?
      records = records.where('protocols.archived_on > ?', params[:archived_on_from])
    end
    records = records.where('protocols.archived_on < ?', params[:archived_on_to]) if params[:archived_on_to].present?

    records = records.where(protocols: { archived_by_id: params[:archived_by] }) if params[:archived_by].present?

    if params[:has_draft].present?
      records = records.where(protocols: { protocol_type: Protocol.protocol_types[:in_repository_draft] })
    end

    records
  end

  def get_raw_records_base
    records =
      Protocol
      .where(team: @team)
      .where('protocols.protocol_type = ? OR protocols.protocol_type = ? AND protocols.parent_id IS NULL',
             Protocol.protocol_types[:in_repository_published_original],
             Protocol.protocol_types[:in_repository_draft])
      .joins('LEFT OUTER JOIN "user_assignments" "all_user_assignments" '\
             'ON "all_user_assignments"."assignable_type" = \'Protocol\' '\
             'AND "all_user_assignments"."assignable_id" = "protocols"."id"')
      .joins("LEFT OUTER JOIN protocols protocol_versions "\
             "ON protocol_versions.protocol_type = #{Protocol.protocol_types[:in_repository_published_version]} "\
             "AND protocol_versions.parent_id = protocols.id")
      .joins("LEFT OUTER JOIN protocols protocol_drafts "\
             "ON protocol_drafts.protocol_type = #{Protocol.protocol_types[:in_repository_draft]} "\
             "AND protocol_drafts.parent_id = protocols.id")
      .joins('LEFT OUTER JOIN "protocol_protocol_keywords" '\
             'ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
      .joins('LEFT OUTER JOIN "protocol_keywords" '\
             'ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')
      .with_granted_permissions(@user, ProtocolPermissions::READ)
      .preload(user_assignments: %i(user user_role))

    records = records.joins('LEFT OUTER JOIN "users" "archived_users"
                             ON "archived_users"."id" = "protocols"."archived_by_id"')
    records = records.joins('LEFT OUTER JOIN "users" ON "users"."id" = "protocols"."added_by_id"')

    records = @type == :archived ? records.archived : records.active

    records = filter_protocols_records(records)
    records.group('"protocols"."id"')
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    get_raw_records_base.select(
      '"protocols".*',
      'STRING_AGG("protocol_keywords"."name", \', \') AS "protocol_keywords_str"',
      'COUNT("protocol_versions"."id") + 1 AS "nr_of_versions"',
      'COUNT("protocol_drafts"."id") AS "nr_of_drafts"',
      'COUNT("user_assignments"."id") AS "nr_of_assigned_users"',
      'MAX("users"."full_name") AS "full_username_str"', # "Hack" to get single username
      'MAX("archived_users"."full_name") AS "archived_full_username_str"'
    )
  end

  # Various helper methods

  def name_html(record)
    "<a href='#{protocol_path(record)}'>#{escape_input(record.name)}</a>"
  end

  def keywords_html(record)
    if !record.protocol_keywords_str || record.protocol_keywords_str.blank?
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
    "<a href='#' data-action='load-linked-children'" \
      "data-url='#{linked_children_protocol_path(record)}'>" \
      "#{record.nr_of_linked_children}"  \
      "</a>"
  end

  def versions_html(record)
    @view.controller
         .render_to_string(partial: 'protocols/index/protocol_versions.html.erb', locals: { protocol: record })
  end

  def access_html(record)
    @view.controller.render_to_string(partial: 'protocols/index/protocol_access.html.erb', locals: { protocol: record })
  end

  def timestamp_column_html(record)
    if @type == :archived
      I18n.l(record.archived_on, format: :full)
    else
      I18n.l(record.published_on || record.created_at, format: :full)
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
  # def build_conditions_for(query)
  #   # Inner query to retrieve list of protocol IDs where concatenated
  #   # protocol keywords string, or user's full_name contains searched query
  #   search_val = dt_params[:search][:value]
  #   records_having = get_raw_records_base.having(
  #     ::Arel::Nodes::NamedFunction.new(
  #       'CAST',
  #       [::Arel::Nodes::SqlLiteral.new("string_agg(\"protocol_keywords\".\"name\", ' ') AS #{typecast}")]
  #     ).matches("%#{sanitize_sql_like(search_val)}%").to_sql +
  #     " OR " +
  #     ::Arel::Nodes::NamedFunction.new(
  #       'CAST',
  #       [::Arel::Nodes::SqlLiteral.new("max(\"users\".\"full_name\") AS #{typecast}")]
  #     ).matches("%#{sanitize_sql_like(search_val)}%").to_sql
  #   ).select(:id)

  #   # Call parent function
  #   criteria = super(query)

  #   # Aight, now append another or
  #   criteria = criteria.or(Protocol.arel_table[:id].in(records_having.arel))
  #   criteria
  # end
end
