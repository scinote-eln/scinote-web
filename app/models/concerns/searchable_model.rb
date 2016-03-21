module SearchableModel
  extend ActiveSupport::Concern

  included do

    # Helper function for relations that
    # adds OR ILIKE where clause for all specified attributes
    # for the given search query
    scope :where_attributes_like, ->(attributes, query) do
      attrs = []
      if attributes.blank? or query.blank?
        # Do nothing in this case
      elsif attributes.is_a? Symbol
        attrs = [attributes.to_s]
      elsif attributes.is_a? String
        attrs = [attributes]
      elsif attributes.is_a? Array
        attrs = attributes.collect { |a| a.to_s }
      else
        raise ArgumentError, ":attributes must be an array, symbol or string"
      end

      if (attrs.length > 0)
        new_query = []
        if query.split(" ").length > 1
          split_query = query.split(" ")
          split_query.each do |word|
            new_query << "%" + word + "%"
          end
          rejoined_query = new_query.join("")
        else
          rejoined_query = "%" + query + "%"
        end
        where_str =
          (attrs.map.with_index { |a,i| "#{a} ILIKE :t#{i} OR " }).join[0..-5]
        vals = (attrs.map.with_index { |a,i| [ "t#{i}".to_sym, "#{rejoined_query}" ] }).to_h

        return where(where_str, vals)
      end
    end
  end
end