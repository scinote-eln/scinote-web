# frozen_string_literal: true

module Lists
  class ProtocolsService < BaseService
    PREFIXED_ID_SQL = "('#{Protocol::ID_PREFIX}' || COALESCE(\"protocols\".\"parent_id\", \"protocols\".\"id\"))".freeze

    private

    def fetch_records
      @records = @raw_data.preload(:parent, :latest_published_version, :draft,
                                   :protocol_keywords, user_assignments: %i(user user_role))
                          .joins("LEFT OUTER JOIN protocols protocol_versions " \
                                 "ON protocol_versions.protocol_type = #{
                                  Protocol.protocol_types[:in_repository_published_version]} " \
                                 "AND protocol_versions.parent_id = protocols.parent_id")
                          .joins("LEFT OUTER JOIN protocols self_linked_task_protocols " \
                                 "ON self_linked_task_protocols.protocol_type = #{
                                  Protocol.protocol_types[:linked]} " \
                                 "AND self_linked_task_protocols.parent_id = protocols.id")
                          .joins("LEFT OUTER JOIN protocols parent_linked_task_protocols " \
                                 "ON parent_linked_task_protocols.protocol_type = #{
                                  Protocol.protocol_types[:linked]} " \
                                 "AND parent_linked_task_protocols.parent_id = protocols.parent_id")
                          .joins("LEFT OUTER JOIN protocols version_linked_task_protocols " \
                                 "ON version_linked_task_protocols.protocol_type = #{
                                  Protocol.protocol_types[:linked]} " \
                                 "AND version_linked_task_protocols.parent_id = protocol_versions.id " \
                                 "AND version_linked_task_protocols.parent_id != protocols.id")
                          .joins('LEFT OUTER JOIN "protocol_protocol_keywords" ' \
                                 'ON "protocol_protocol_keywords"."protocol_id" = "protocols"."id"')
                          .joins('LEFT OUTER JOIN "protocol_keywords" ' \
                                 'ON "protocol_protocol_keywords"."protocol_keyword_id" = "protocol_keywords"."id"')
                          .joins('LEFT OUTER JOIN "users" "archived_users"
                                  ON "archived_users"."id" = "protocols"."archived_by_id"')
                          .joins('LEFT OUTER JOIN "users" ON "users"."id" = "protocols"."published_by_id"')
                          .joins('LEFT OUTER JOIN "user_assignments" "all_user_assignments" ' \
                                 'ON "all_user_assignments"."assignable_type" = \'Protocol\' ' \
                                 'AND "all_user_assignments"."assignable_id" = "protocols"."id"')
                          .group('"protocols"."id"')
                          .select(
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

      view_mode = @params[:view_mode] || 'active'

      @records = @records.archived if view_mode == 'archived'
      @records = @records.active if view_mode == 'active'
    end

    def filter_records
      return if @params[:search].blank?

      @records = @records.where(
        "LOWER(\"protocols\".\"name\") LIKE :search OR
         LOWER(\"protocol_keywords\".\"name\") LIKE :search OR
         LOWER(#{PREFIXED_ID_SQL}) LIKE :search",
        search: "%#{@params[:search].to_s.downcase}%"
      )
    end

    def sortable_columns
      @sortable_columns ||= {
        name: 'name',
        parent_id: 'adjusted_parent_id',
        versions: 'nr_of_versions',
        keywords: 'protocol_keywords_str',
        linked_tasks: 'nr_of_linked_tasks',
        assigned_users: 'nr_of_assigned_users',
        published_by: 'full_username_str',
        published_on: 'published_on',
        udpated_at: 'updated_at',
        archived_by: 'archived_full_username_str',
        archived_on: 'archived_on'
      }
    end
  end
end
