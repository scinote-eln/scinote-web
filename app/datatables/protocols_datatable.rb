# frozen_string_literal: true

class ProtocolsDatatable < CustomDatatable
  # Needed for sanitize_sql_like method
  include ActiveRecord::Sanitization::ClassMethods
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers
  include Canaid::Helpers::PermissionsHelper

  PREFIXED_ID_SQL = "('#{Protocol::ID_PREFIX}' || COALESCE(\"protocols\".\"parent_id\", \"protocols\".\"id\"))"

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
      'nr_of_linked_tasks',
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
      recordsTotal: get_raw_records_base.distinct.count,
      recordsFiltered: records.present? ? records.first.filtered_count : 0,
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
    casted_column.matches("%#{ActiveRecord::Base.sanitize_sql_like(value)}%")
  end

  private

  # Returns json of current protocols (already paginated)
  def data
    records.map do |record|
      parent = record.parent || record
      {
        DT_RowId: record.id,
        DT_RowAttr: {
          'data-permissions-url': permissions_protocol_path(parent),
          'data-versions-url': versions_modal_protocol_path(parent)
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

  def fetch_records
    super.select('COUNT("protocols"."id") OVER() AS filtered_count')
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
      records = records.where(all_user_assignments: { user_id: params[:members] })
    end

    if params[:archived_on_from].present?
      records = records.where('protocols.archived_on > ?', params[:archived_on_from])
    end
    records = records.where('protocols.archived_on < ?', params[:archived_on_to]) if params[:archived_on_to].present?

    records = records.where(protocols: { archived_by_id: params[:archived_by] }) if params[:archived_by].present?

    if params[:has_draft].present?
      records =
        records
        .joins("LEFT OUTER JOIN protocols protocol_drafts " \
               "ON protocol_drafts.protocol_type = #{Protocol.protocol_types[:in_repository_draft]} " \
               "AND (protocol_drafts.parent_id = protocols.id OR protocol_drafts.parent_id = protocols.parent_id)")
        .where('protocols.protocol_type = ? OR protocol_drafts.id IS NOT NULL',
               Protocol.protocol_types[:in_repository_draft])
    end

    records
  end

  def get_raw_records_base
    records = Protocol.latest_available_versions(@team)

    records = @type == :archived ? records.archived : records.active

    records.viewable_by_user(@user, @team)
  end

  # Query database for records (this will be later paginated and filtered)
  # after that "data" function will return json
  def get_raw_records
    records =
      get_raw_records_base
      .preload(:parent, :latest_published_version, :draft, :protocol_keywords, user_assignments: %i(user user_role))
      .joins("LEFT OUTER JOIN protocols protocol_versions " \
             "ON protocol_versions.protocol_type = #{Protocol.protocol_types[:in_repository_published_version]} " \
             "AND protocol_versions.parent_id = protocols.parent_id")
      .joins("LEFT OUTER JOIN protocols self_linked_task_protocols " \
             "ON self_linked_task_protocols.protocol_type = #{Protocol.protocol_types[:linked]} " \
             "AND self_linked_task_protocols.parent_id = protocols.id")
      .joins("LEFT OUTER JOIN protocols parent_linked_task_protocols " \
             "ON parent_linked_task_protocols.protocol_type = #{Protocol.protocol_types[:linked]} " \
             "AND parent_linked_task_protocols.parent_id = protocols.parent_id")
      .joins("LEFT OUTER JOIN protocols version_linked_task_protocols " \
             "ON version_linked_task_protocols.protocol_type = #{Protocol.protocol_types[:linked]} " \
             "AND version_linked_task_protocols.parent_id = protocol_versions.id " \
             "AND version_linked_task_protocols.parent_id != protocols.id")
      .joins('LEFT OUTER JOIN "protocol_protocol_keywords" ' \
             'ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
      .joins('LEFT OUTER JOIN "protocol_keywords" ' \
             'ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')
      .joins('LEFT OUTER JOIN "users" "archived_users" ON "archived_users"."id" = "protocols"."archived_by_id"')
      .joins('LEFT OUTER JOIN "users" ON "users"."id" = "protocols"."published_by_id"')
      .joins('LEFT OUTER JOIN "user_assignments" "all_user_assignments" ' \
             'ON "all_user_assignments"."assignable_type" = \'Protocol\' ' \
             'AND "all_user_assignments"."assignable_id" = "protocols"."id"')
      .group('"protocols"."id"')

    records = filter_protocols_records(records)
    records.select(
      '"protocols".*',
      'COALESCE("protocols"."parent_id", "protocols"."id") AS adjusted_parent_id',
      'STRING_AGG(DISTINCT("protocol_keywords"."name"), \', \') AS "protocol_keywords_str"',
      "CASE WHEN protocols.protocol_type = #{Protocol.protocol_types[:in_repository_draft]} " \
      "THEN 0 ELSE COUNT(DISTINCT(\"protocol_versions\".\"id\")) + 1 " \
      "END AS nr_of_versions",
      '(COUNT(DISTINCT("self_linked_task_protocols"."id")) + ' \
      'COUNT(DISTINCT("parent_linked_task_protocols"."id")) + ' \
      'COUNT(DISTINCT("version_linked_task_protocols"."id"))) AS nr_of_linked_tasks',
      'COUNT(DISTINCT("all_user_assignments"."id")) AS "nr_of_assigned_users"',
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

    if can_read_protocol_in_repository?(@user, record)
      "<a href='#{path}'>#{escape_input(record.name)}</a>"
    else
      # team admin can only see recod name
      "<span class='not-clickable-record'>#{escape_input(record.name)}</span>"
    end
  end

  def keywords_html(record)
    if record.protocol_keywords.blank?
      I18n.t('protocols.no_keywords')
    else
      res = []
      record.protocol_keywords.sort_by { |kw| kw.name.downcase }.each do |kw|
        sanitized_kw = escape_input(kw.name)
        res << "<a href='#' data-action='filter' data-param='#{sanitized_kw}'>#{sanitized_kw}</a>"
      end
      res.join(', ')
    end
  end

  def modules_html(record)
    "<a href='#' data-action='load-linked-children'" \
      "data-url='#{linked_children_protocol_path(record.parent || record)}'>" \
      "#{record.nr_of_linked_tasks}" \
      "</a>"
  end

  def versions_html(record)
    @view.controller
         .render_to_string(partial: 'protocols/index/protocol_versions.html.erb',
                           locals: { protocol: record, readable: can_read_protocol_in_repository?(@user, record) })
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
end
