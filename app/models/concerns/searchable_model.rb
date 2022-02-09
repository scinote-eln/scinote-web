# frozen_string_literal: true

module SearchableModel
  extend ActiveSupport::Concern

  included do
    # Helper function for relations that
    # adds OR ILIKE where clause for all specified attributes
    # for the given search query
    scope :where_attributes_like, lambda { |attributes, query, options = {}|
      return unless query

      attrs = []
      if attributes.blank?
        # Do nothing in this case
      elsif attributes.is_a? Symbol
        attrs = [attributes.to_s]
      elsif attributes.is_a? String
        attrs = [attributes]
      elsif attributes.is_a? Array
        attrs = attributes.collect(&:to_s)
      else
        raise ArgumentError, ':attributes must be an array, symbol or string'
      end

      if options[:whole_word].to_s == 'true' ||
         options[:whole_phrase].to_s == 'true' ||
         options[:at_search].to_s == 'true'
        unless attrs.blank?
          like = options[:match_case].to_s == 'true' ? '~' : '~*'
          like = 'SIMILAR TO' if options[:at_search].to_s == 'true'

          if options[:whole_word].to_s == 'true'
            a_query = query.split
                           .map { |a| Regexp.escape(a) }
                           .join('|')
            a_query = "(#{a_query})"
          elsif options[:at_search].to_s == 'true'
            a_query = "%#{Regexp.escape(query).downcase}%"
          else
            a_query = Regexp.escape(query)
          end

          where_str =
            (attrs.map.with_index do |a, i|
              if %w(repository_rows.id repository_number_values.data).include?(a)
                "((#{a})::text) #{like} :t#{i} OR "
              elsif defined?(model::PREFIXED_ID_SQL) && a == model::PREFIXED_ID_SQL
                "#{a} #{like} :t#{i} OR "
              else
                col = options[:at_search].to_s == 'true' ? "lower(#{a})": a
                "(trim_html_tags(#{col})) #{like} :t#{i} OR "
              end
            end
            ).join[0..-5]
          vals = (
            attrs.map.with_index do |_, i|
              ["t#{i}".to_sym, a_query]
            end
          ).to_h
          return where(where_str, vals)
        end
      end

      like = options[:match_case].to_s == 'true' ? 'LIKE' : 'ILIKE'

      if query.count(' ') > 0
        unless attrs.blank?
          a_query = query.split.map { |a| "%#{sanitize_sql_like(a)}%" }
          where_str =
            (attrs.map.with_index do |a, i|
              if %w(repository_rows.id repository_number_values.data).include?(a)
                "((#{a})::text) #{like} ANY (array[:t#{i}]) OR "
              elsif defined?(model::PREFIXED_ID_SQL) && a == model::PREFIXED_ID_SQL
                "#{a} #{like} ANY (array[:t#{i}]) OR "
              else
                "(trim_html_tags(#{a})) #{like} ANY (array[:t#{i}]) OR "
              end
            end
            ).join[0..-5]
          vals = (
            attrs.map.with_index do |_, i|
              ["t#{i}".to_sym, a_query]
            end
          ).to_h

          return where(where_str, vals)
        end
      else
        unless attrs.blank?
          where_str =
            (attrs.map.with_index do |a, i|
              if %w(repository_rows.id repository_number_values.data).include?(a)
                "((#{a})::text) #{like} :t#{i} OR "
              elsif defined?(model::PREFIXED_ID_SQL) && a == model::PREFIXED_ID_SQL
                "#{a} #{like} :t#{i} OR "
              else
                "(trim_html_tags(#{a})) #{like} :t#{i} OR "
              end
            end
            ).join[0..-5]
          vals = (
            attrs.map.with_index do |_, i|
              ["t#{i}".to_sym, "%#{sanitize_sql_like(query.to_s)}%"]
            end
          ).to_h

          return where(where_str, vals)
        end
      end
    }
  end
end
