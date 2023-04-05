class LoadFromRepositoryProtocolsDatatable < CustomDatatable
  # Needed for sanitize_sql_like method
  include ActiveRecord::Sanitization::ClassMethods
  include InputSanitizeHelper

  PREFIXED_ID_SQL = "('#{Protocol::ID_PREFIX}' || COALESCE(\"protocols\".\"parent_id\", \"protocols\".\"id\"))".freeze

  def initialize(view, team, user)
    super(view)
    @team = team
    @user = user
  end

  def sortable_columns
    @sortable_columns ||= [
      'Protocol.name',
      'Protocol.version_number',
      'adjusted_parent_id',
      'protocol_keywords_str',
      'full_username_str',
      'Protocol.published_on'
    ]
  end

  def searchable_columns
    @searchable_columns ||= [
      'Protocol.name',
      "Protocol.#{PREFIXED_ID_SQL}",
      'Protocol.published_on',
      'Protocol.version_number',
      'ProtocolKeyword.name'
    ]
  end

  def as_json(_options = {})
    {
      draw: dt_params[:draw].to_i,
      recordsTotal: get_raw_records_base.distinct.count,
      recordsFiltered: records.present? ? records.first.filtered_count : 0,
      data: data
    }
  end

  private

  # Returns json of current protocols (already paginated)
  def data
    records.map do |record|
      parent = record.parent || record
      {
        DT_RowId: parent.id,
        '0': escape_input(record.name),
        '1': record.version_number,
        '2': parent.code,
        '3': keywords_html(record),
        '4': escape_input(record.published_by&.full_name),
        '5': I18n.l(record.published_on, format: :full)
      }
    end
  end

  def new_search_condition(column, value)
    model, column = column.split('.', 2)
    model = model.constantize

    casted_column = case column
                    when PREFIXED_ID_SQL
                      ::Arel::Nodes::SqlLiteral.new(PREFIXED_ID_SQL)
                    when 'published_on'
                      ::Arel::Nodes::NamedFunction.new(
                        'CAST', [Arel.sql("to_char( protocols.published_on, '#{formated_date}' ) AS VARCHAR")]
                      )
                    else
                      ::Arel::Nodes::NamedFunction.new('CAST', [model.arel_table[column.to_sym].as(typecast)])
                    end
    casted_column.matches("%#{ActiveRecord::Base.sanitize_sql_like(value)}%")
  end

  def fetch_records
    super.select('COUNT("protocols"."id") OVER() AS filtered_count')
  end

  def get_raw_records_base
    original_without_versions = @team.protocols
                                     .left_outer_joins(:published_versions)
                                     .where(protocol_type: Protocol.protocol_types[:in_repository_published_original])
                                     .where(published_versions: { id: nil })
                                     .select(:id)

    published_versions = @team.protocols
                              .where(protocol_type: Protocol.protocol_types[:in_repository_published_version])
                              .order('parent_id, version_number DESC')
                              .select('DISTINCT ON (parent_id) id')

    Protocol.where("protocols.id IN ((#{original_without_versions.to_sql}) UNION (#{published_versions.to_sql}))")
            .active
            .with_granted_permissions(@user, ProtocolPermissions::READ)
  end

  # OVERRIDE - query database for records (this will be
  # later paginated and filtered) after that "data" function
  # will return json
  def get_raw_records
    get_raw_records_base
      .preload(:parent, :protocol_keywords, user_assignments: %i(user user_role))
      .joins('LEFT OUTER JOIN "protocol_protocol_keywords" ' \
             'ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
      .joins('LEFT OUTER JOIN "protocol_keywords" ' \
             'ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')
      .joins('LEFT OUTER JOIN "users" ON "users"."id" = "protocols"."published_by_id"')
      .group('"protocols"."id"')
      .select(
        '"protocols".*',
        'COALESCE("protocols"."parent_id", "protocols"."id") AS adjusted_parent_id',
        'STRING_AGG(DISTINCT("protocol_keywords"."name"), \', \') AS "protocol_keywords_str"',
        'MAX("users"."full_name") AS "full_username_str"'
      )
  end

  # Various helper methods

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
end
