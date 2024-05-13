# frozen_string_literal: true

module SearchableModel
  extend ActiveSupport::Concern

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

      attrs = normalized_attributes(attributes)
      where_array = []
      value_array = {}
      current_phrase = ''
      exact_match = false
      negate = false
      index = 0

      query.split.each do |phrase|
        phrase = phrase.strip
        if phrase.start_with?('"') && phrase.ends_with?('"')
          create_query(attrs, index, negate, where_array, value_array, phrase[1..-2], true)
          negate = false
        elsif phrase.start_with?('"')
          exact_match = true
          current_phrase = phrase[1..]
        elsif exact_match && phrase.ends_with?('"')
          exact_match = false
          create_query(attrs, index, negate, where_array, value_array, "#{current_phrase} #{phrase[0..-2]}", true)
          current_phrase = ''
          negate = false
        elsif exact_match
          current_phrase = "#{current_phrase} #{phrase}"
        elsif phrase.casecmp('and').zero?
          next
        elsif phrase.casecmp('not').zero?
          negate = true
        elsif phrase.casecmp('or').zero?
          where_array[-1] = "#{where_array.last[0..-5]} OR "
        else
          create_query(attrs, index, negate, where_array, value_array, "%#{phrase}%")
          negate = false
        end
        index += 1
      end

      if current_phrase.present?
        current_phrase = current_phrase[0..-2] if current_phrase.ends_with?('"')
        create_query(attrs, index, negate, where_array, value_array, current_phrase, true)
      end

      where(where_array.join[0..-5], value_array)
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

    def self.create_query(attrs, index, negate, where_array, value_array, phrase, exact_match=false)
      like = exact_match ? '~' : 'ILIKE'
      phrase = "\\m#{phrase}\\M" if exact_match

      where_clause = (attrs.map.with_index do |a, i|
        i = (index * attrs.count) + i
        if %w(repository_rows.id repository_number_values.data).include?(a)
          "#{a} IS NOT NULL AND (((#{a})::text) #{like} :t#{i}) OR "
        elsif defined?(model::PREFIXED_ID_SQL) && a == model::PREFIXED_ID_SQL
          "#{a} IS NOT NULL AND (#{a} #{like} :t#{i}) OR "
        elsif a == 'asset_text_data.data_vector'
          "asset_text_data.data_vector @@ plainto_tsquery(:t#{i})) OR"
        else
          "#{a} IS NOT NULL AND ((trim_html_tags(#{a})) #{like} :t#{i}) OR "
        end
      end).join[0..-5]

      where_array << if negate
                       "NOT (#{where_clause}) AND "
                     else
                       "(#{where_clause}) AND "
                     end

      value_array.merge!(
        (attrs.map.with_index do |_, i|
          i = (index * attrs.count) + i
          ["t#{i}".to_sym, phrase]
        end).to_h
      )
    end
  end
end
