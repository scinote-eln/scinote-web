# frozen_string_literal: true

class ProtocolsDatatable < CustomDatatable
  # Needed for sanitize_sql_like method
  include ActiveRecord::Sanitization::ClassMethods
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  PREFIXED_ID_SQL = "('#{Protocol::ID_PREFIX}' || COALESCE(\"protocols\".\"parent_id\", \"protocols\".\"id\"))"

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
    @type = type # :active or :archived
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      'name',
      'adjusted_parent_id',
      'nr_of_versions',
      'protocol_keywords_str',
      'nr_of_linked_children',
      'nr_of_assigned_users',
      'full_username_str',
      'published_on',
      'updated_at',
      'archived_full_username_str',
      'archived_on'
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      'Protocol.name',
      'Protocol.archived_on',
      'Protocol.published_on',
      "Protocol.#{PREFIXED_ID_SQL}",
      'Protocol.updated_at',
      'ProtocolKeyword.name'
    ]
  end

  def as_json(_options = {})
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
    when PREFIXED_ID_SQL
      casted_column = ::Arel::Nodes::SqlLiteral.new(PREFIXED_ID_SQL)
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
      parent = record.parent || record
      {
        DT_RowId: record.id,
        DT_RowAttr: {
          'data-permissions-url': permissions_protocol_path(parent)
        },
        '1': name_html(parent),
        '2': parent.code,
        '3': versions_html(record),
        '4': keywords_html(record),
        '5': modules_html(record),
        '6': access_html(parent),
        '7': published_by(record),
        '8': published_timestamp(record),
        '9': modified_timestamp(record),
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
    records = records.where(all_user_assignments: { user_id: params[:members] }) if params[:members].present?

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
    original_without_versions = @team.protocols
                                     .left_outer_joins(:published_versions)
                                     .where(protocol_type: Protocol.protocol_types[:in_repository_published_original])
                                     .where(published_versions: { id: nil })
                                     .select(:id)
    published_versions = @team.protocols
                              .where(protocol_type: Protocol.protocol_types[:in_repository_published_version])
                              .select('DISTINCT ON (parent_id) id')
    new_drafts = @team.protocols
                      .where(protocol_type: Protocol.protocol_types[:in_repository_draft], parent_id: nil)
                      .select(:id)

    records = Protocol.where(
      "protocols.id IN ((#{original_without_versions.to_sql}) " \
      "UNION " \
      "(#{published_versions.to_sql}) " \
      "UNION " \
      "(#{new_drafts.to_sql}))"
    )

    records =
      records
      .preload(:parent, :latest_published_version, :draft, :protocol_keywords, user_assignments: %i(user user_role))
      .joins("LEFT OUTER JOIN protocols protocol_versions " \
             "ON protocol_versions.protocol_type = #{Protocol.protocol_types[:in_repository_published_version]} " \
             "AND protocol_versions.parent_id = protocols.parent_id")
      .joins('LEFT OUTER JOIN "protocol_protocol_keywords" ' \
             'ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
      .joins('LEFT OUTER JOIN "protocol_keywords" ' \
             'ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')
      .with_granted_permissions(@user, ProtocolPermissions::READ)

    records = records.joins('LEFT OUTER JOIN "users" "archived_users"
                             ON "archived_users"."id" = "protocols"."archived_by_id"')
    records = records.joins('LEFT OUTER JOIN "users" ON "users"."id" = "protocols"."published_by_id"')

    records = @type == :archived ? records.archived : records.active

    records = filter_protocols_records(records)
    records.group('"protocols"."id"')
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    get_raw_records_base.select(
      '"protocols".*',
      'COALESCE("protocols"."parent_id", "protocols"."id") AS adjusted_parent_id',
      'STRING_AGG(DISTINCT("protocol_keywords"."name"), \', \') AS "protocol_keywords_str"',
      "CASE WHEN protocols.protocol_type = #{Protocol.protocol_types[:in_repository_draft]}" \
      "THEN COUNT(DISTINCT(\"protocol_versions\".\"id\")) ELSE COUNT(DISTINCT(\"protocol_versions\".\"id\")) + 1 " \
      "END AS nr_of_versions",
      'COUNT("user_assignments"."id") AS "nr_of_assigned_users"',
      'MAX("users"."full_name") AS "full_username_str"', # "Hack" to get single username
      'MAX("archived_users"."full_name") AS "archived_full_username_str"'
    )
  end

  # Various helper methods

  def name_html(record)
    path =
      if record.in_repository_published_original? && record.latest_published_version.present?
        protocol_path(record.latest_published_version)
      else
        protocol_path(record)
      end
    "<a href='#{path}'>#{escape_input(record.name)}</a>"
  end

  def keywords_html(record)
    if record.protocol_keywords.blank?
      "<i>#{I18n.t('protocols.no_keywords')}</i>"
    else
      res = []
      record.protocol_keywords.sort_by { |kw| kw.name.downcase }.each do |kw|
        sanitized_kw = sanitize_input(kw.name)
        res << "<a href='#' data-action='filter' data-param='#{sanitized_kw}'>#{sanitized_kw}</a>"
      end
      res.join(', ')
    end
  end

  def modules_html(record)
    "<a href='#' data-action='load-linked-children'" \
      "data-url='#{linked_children_protocol_path(record)}'>" \
      "#{record.nr_of_linked_children}" \
      "</a>"
  end

  def versions_html(record)
    @view.controller
         .render_to_string(partial: 'protocols/index/protocol_versions.html.erb', locals: { protocol: record })
  end

  def access_html(record)
    @view.controller.render_to_string(partial: 'protocols/index/protocol_access.html.erb', locals: { protocol: record })
  end

  def published_by(record)
    return '' if record.published_by.blank?

    escape_input(record.published_by.full_name)
  end

  def published_timestamp(record)
    return '' if record.published_on.blank?

    I18n.l(record.published_on, format: :full)
  end

  def modified_timestamp(record)
    I18n.l(record.updated_at, format: :full)
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
