module SearchableModelTestHelper

  def attributes_like_test(clazz, attributes, query)
    if attributes.blank? or query.blank?
      attrs = []
    elsif attributes.is_a? Symbol
      attrs = [attributes.to_s]
    elsif attributes.is_a? String
      attrs = [attributes]
    elsif attributes.is_a? Array
      attrs = attributes.collect { |a| a.to_s }
    else
      raise ArgumentError, ":attributes must be an array, symbol or string"
    end

    results = clazz.all.where_attributes_like(attrs, query)
    unless results.blank?
      equery = "#{query.downcase}"
      results.each do |result|
        cntr = 0
        attrs.each do |attr|
          val = eval("result.#{attr}").downcase
          if (val =~ /.*#{equery}.*/) then
            cntr += 1
          end
        end

        assert cntr > 0, "Not all attributes are matching"
      end
    end
  end

end