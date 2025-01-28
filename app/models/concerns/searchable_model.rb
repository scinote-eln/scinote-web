# frozen_string_literal: true

module SearchableModel
  extend ActiveSupport::Concern
  DATA_VECTOR_ATTRIBUTES = ['asset_text_data.data_vector', 'tables.data_vector'].freeze

  included do
    # Helper function for relations that
    # adds OR ILIKE where clause for all specified attributes
    # for the given search query
    scope :where_attributes_like, lambda { |attributes, query, options = {}|
      return unless query

      attrs = normalized_attributes(attributes)

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

    scope :where_attributes_like_boolean, lambda { |attributes, query, options = {}|
      return unless query

      normalized_attrs = normalized_attributes(attributes)
      query_clauses = []
      value_hash = {}

      extract_phrases(query).each_with_index do |phrase, index|
        if options[:with_subquery]
          subquery_result = if phrase[:negate]
                              options[:raw_input].where.not(id: search_subquery(phrase[:query], options[:raw_input]))
                            else
                              options[:raw_input].where(id: search_subquery(phrase[:query], options[:raw_input]))
                            end
          query_clauses = if index.zero?
                            where(id: subquery_result)
                          elsif phrase[:current_operator] == 'or'
                            query_clauses.or(subquery_result)
                          else
                            query_clauses.and(subquery_result)
                          end
        else
          phrase[:current_operator] = '' if index.zero?
          create_query_clause(normalized_attrs, index, phrase[:negate], query_clauses,
                              value_hash, phrase[:query], phrase[:current_operator])
        end
      end

      options[:with_subquery] ? query_clauses : where(query_clauses.join, value_hash)
    }

    def self.normalized_attributes(attributes)
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

      attrs
    end

    def self.extract_phrases(query)
      extracted_phrases = []
      negate = false
      current_operator = ''

      query.scan(/"[^"]+"|\S+/) do |phrase|
        phrase = phrase.to_s.strip

        case phrase.downcase
        when *%w(and or)
          current_operator = phrase.downcase
        when 'not'
          negate = true
        else
          extracted_phrases << { query: phrase,
                                 negate: negate,
                                 current_operator: current_operator.presence || 'and' }
          current_operator = ''
          negate = false
        end
      end

      extracted_phrases
    end

    def self.create_query_clause(attrs, index, negate, query_clauses, value_hash, phrase, current_operator)
      exact_match = phrase =~ /^".*"$/
      like = exact_match ? '~' : 'ILIKE'

      where_clause = (attrs.map.with_index do |attribute, i|
        i = (index * attrs.count) + i
        if %w(repository_rows.id repository_number_values.data).include?(attribute)
          "#{attribute} IS NOT NULL AND (((#{attribute})::text) #{like} :t#{i}) OR "
        elsif defined?(model::PREFIXED_ID_SQL) && attribute == model::PREFIXED_ID_SQL
          "#{attribute} IS NOT NULL AND (#{attribute} #{like} :t#{i}) OR "
        elsif DATA_VECTOR_ATTRIBUTES.include?(attribute)
          "#{attribute} @@ to_tsquery(:t#{i}) OR "
        else
          "#{attribute} IS NOT NULL AND ((trim_html_tags(#{attribute})) #{like} :t#{i}) OR "
        end
      end).join[0..-5]

      query_clauses << if negate
                         " #{current_operator} NOT (#{where_clause})"
                       else
                         "#{current_operator} (#{where_clause})"
                       end

      value_hash.merge!(
        (attrs.map.with_index do |attribute, i|
          i = (index * attrs.count) + i

          new_phrase = exact_match ? phrase[1..-2] : phrase
          if DATA_VECTOR_ATTRIBUTES.include?(attribute)
            new_phrase = Regexp.escape(new_phrase.gsub(/[!()&|:<]/, ' ').strip).split(/\s+/)
            new_phrase.map! { |t| "#{t}:*" } unless exact_match
            new_phrase = sanitize_sql_like(new_phrase.join('&').tr('\'', '"'))
          else
            new_phrase = sanitize_sql_like(Regexp.escape(new_phrase))
            new_phrase = exact_match ? "(^|\\s)#{new_phrase}(\\s|$)" : "%#{new_phrase}%"
          end

          ["t#{i}".to_sym, new_phrase]
        end).to_h
      )
    end

    def self.search_subquery(query, raw_input)
      raise NotImplementedError
    end
  end
end
