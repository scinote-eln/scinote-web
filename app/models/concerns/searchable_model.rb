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
         options[:whole_phrase].to_s == 'true'
        unless attrs.empty?
          like = options[:match_case].to_s == 'true' ? '~' : '~*'

          if options[:whole_word].to_s == 'true'
            a_query = query.split
                           .map { |a| Regexp.escape(a) }
                           .join('|')
          else
            a_query = Regexp.escape(query)
          end
          a_query = '\\y(' + a_query + ')\\y'
          where_str =
            (attrs.map.with_index do |a, i|
              "(trim_html_tags(#{a})) #{like} :t#{i} OR "
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
        unless attrs.empty?
          a_query = query.split.map { |a| "%#{sanitize_sql_like(a)}%" }
          where_str =
            (attrs.map.with_index do |a, i|
              "(trim_html_tags(#{a})) #{like} ANY (array[:t#{i}]) OR "
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
        unless attrs.empty?
          where_str =
            (attrs.map.with_index do |a, i|
              "(trim_html_tags(#{a})) #{like} :t#{i} OR "
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
