# frozen_string_literal: true

module SearchableByNameModel
  extend ActiveSupport::Concern
  # rubocop:disable Metrics/BlockLength
  included do
    def self.search_by_name(user, teams = [], query = nil, options = {})
      return if user.blank? || teams.blank?

      sql_q = self

      if options[:intersect]
        query_array = query.gsub(/[[:space:]]+/, ' ').split(' ')
        query_array.each do |string|
          sql_q = sql_q.where("trim_html_tags(#{table_name}.name) ILIKE ?", "%#{string}%")
        end
      else
        sql_q = sql_q.where_attributes_like("#{table_name}.name", query, options)
      end

      sql_q = sql_q.where(id: viewable_by_user(user, teams))

      sql_q.limit(Constants::SEARCH_LIMIT)
    end

    def self.search_by_name_and_id(user, teams = [], query = nil)
      return if user.blank? || teams.blank?

      sanitized_query = ActiveRecord::Base.sanitize_sql_like(query.to_s)

      sql_q = viewable_by_user(user, teams).where(
        "trim_html_tags(#{table_name}.name) ILIKE ? OR " \
        " #{self::PREFIXED_ID_SQL} ILIKE ? ",
        "%#{sanitized_query}%", "%#{sanitized_query}%"
      )

      sql_q.limit(Constants::SEARCH_LIMIT)
    end
  end
  # rubocop:enable Metrics/BlockLength
end
