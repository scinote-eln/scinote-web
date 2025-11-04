# frozen_string_literal: true

module SearchableModel
  extend ActiveSupport::Concern
  SEARCH_DATA_VECTOR_ATTRIBUTES = ['asset_text_data.data_vector', 'tables.data_vector'].freeze
  SEARCH_NUMBER_ATTRIBUTES = %w(repository_rows.id repository_number_values.data).freeze

  included do
    # Helper function for relations that
    # adds OR ILIKE where clause for all specified attributes
    # for the given search query
    scope :where_attributes_like, lambda { |attributes, query, options = {}|
      return unless query

      attrs = normalized_search_attributes(attributes)

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
              if SEARCH_NUMBER_ATTRIBUTES.include?(a)
                "((#{a})::text) #{like} :t#{i} OR "
              elsif defined?(model::PREFIXED_ID_SQL) && a == model::PREFIXED_ID_SQL
                "#{a} #{like} :t#{i} OR "
              elsif SEARCH_DATA_VECTOR_ATTRIBUTES.include?(a)
                "#{a} @@ plainto_tsquery(:t#{i}) OR "
              else
                col = options[:at_search].to_s == 'true' ? "lower(#{a})": a
                "(trim_html_tags(#{col})) #{like} :t#{i} OR "
              end
            end
            ).join[0..-5]
          vals = (
            attrs.map.with_index do |_, i|
              [:"t#{i}", a_query]
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
              if SEARCH_NUMBER_ATTRIBUTES.include?(a)
                "((#{a})::text) #{like} ANY (array[:t#{i}]) OR "
              elsif defined?(model::PREFIXED_ID_SQL) && a == model::PREFIXED_ID_SQL
                "#{a} #{like} ANY (array[:t#{i}]) OR "
              elsif SEARCH_DATA_VECTOR_ATTRIBUTES.include?(a)
                "#{a} @@ plainto_tsquery(:t#{i}) OR "
              else
                "(trim_html_tags(#{a})) #{like} ANY (array[:t#{i}]) OR "
              end
            end
            ).join[0..-5]
          vals = (
            attrs.map.with_index do |_, i|
              [:"t#{i}", a_query]
            end
          ).to_h

          where(where_str, vals)
        end
      else
        unless attrs.blank?
          where_str =
            (attrs.map.with_index do |a, i|
              if SEARCH_NUMBER_ATTRIBUTES.include?(a)
                "((#{a})::text) #{like} :t#{i} OR "
              elsif defined?(model::PREFIXED_ID_SQL) && a == model::PREFIXED_ID_SQL
                "#{a} #{like} :t#{i} OR "
              elsif SEARCH_DATA_VECTOR_ATTRIBUTES.include?(a)
                "#{a} @@ plainto_tsquery(:t#{i}) OR "
              else
                "(trim_html_tags(#{a})) #{like} :t#{i} OR "
              end
            end
            ).join[0..-5]
          vals = (
            attrs.map.with_index do |_, i|
              [:"t#{i}", "%#{sanitize_sql_like(query.to_s)}%"]
            end
          ).to_h

          where(where_str, vals)
        end
      end
    }

    scope :where_attributes_like_boolean, lambda { |attributes, query|
      return unless query

      query_clauses = []
      query_params = {}
      search_tokens = tokenize_search_query(query)

      search_tokens.each_with_index do |token, index|
        if token[:type] == :keyword
          exact_match = token[:value].split.size > 1
          like = exact_match ? '~' : 'ILIKE'

          where_str = (attributes.map do |attribute|
            attribute_key = attribute.to_s.parameterize(separator: '_')

            if attribute == :children
              "\"#{table_name}\".\"id\" IN (#{where_children_attributes_like(token[:value]).select(:id).to_sql}) OR "
            elsif SEARCH_NUMBER_ATTRIBUTES.include?(attribute)
              "(#{attribute} IS NOT NULL AND #{attribute}::text #{like} :#{attribute_key}_#{index}_query) OR "
            elsif defined?(model::PREFIXED_ID_SQL) && attribute == model::PREFIXED_ID_SQL
              "(#{attribute} IS NOT NULL AND #{attribute} #{like} :#{attribute_key}_#{index}_query) OR "
            elsif SEARCH_DATA_VECTOR_ATTRIBUTES.include?(attribute)
              "(#{attribute} IS NOT NULL AND #{attribute} @@ plainto_tsquery(:#{attribute_key}_#{index}_query)) OR "
            else
              "(#{attribute} IS NOT NULL AND trim_html_tags(#{attribute}) #{like} :#{attribute_key}_#{index}_query) OR "
            end
          end).join[0..-5]

          query_clauses << "(#{where_str})"

          attributes.each do |attribute|
            next if attribute == :children

            query_params[:"#{attribute.to_s.parameterize(separator: '_')}_#{index}_query"] =
              if SEARCH_DATA_VECTOR_ATTRIBUTES.include?(attribute) && !exact_match
                token[:value].split(/\s+/).map! { |t| "#{t}:*" }
              else
                exact_match ? "(^|\\s)#{Regexp.escape(token[:value])}(\\s|$)" : "%#{sanitize_sql_like(token[:value])}%"
              end
          end

          next_token = search_tokens[index + 1]
          query_clauses << ' AND ' if next_token && next_token[:type] == :keyword
        elsif token[:type] == :operator
          query_clauses <<
            case token[:value]
            when 'AND'
              ' AND '
            when 'OR'
              ' OR '
            when 'NOT'
              index.zero? ? ' NOT ' : ' AND NOT '
            end
        end
      end

      where(query_clauses.join, query_params)
    }

    def self.normalized_search_attributes(attributes)
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
        when 'and', 'or'
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

    def self.tokenize_search_query(query)
      tokens = []

      # Regular expression to match:
      # - Quoted phrases: "any phrase inside quotes"
      # - Or single word tokens
      pattern = /
        "(.*?)"         |   # Capture quoted phrases
        (\S+)               # Or single non-space word
      /x

      query.scan(pattern) do |quoted, word|
        if quoted
          tokens << { type: :keyword, value: quoted }
        else
          # Check if it's a boolean operator (only if not inside quotes)
          case word.upcase
          when 'AND', 'OR', 'NOT'
            next if tokens.present? && tokens.last[:type] == :operator

            tokens << { type: :operator, value: word.upcase }
          else
            tokens << { type: :keyword, value: word }
          end
        end
      end

      # Remove trailing operator if present
      tokens.pop if tokens.present? && tokens.last[:type] == :operator

      tokens
    end
  end
end
