module ActivityHelper
  TAGS_LENGTH = 4
  TRUNCATE_OFFSET = 3
  def activity_truncate(message, len = Constants::NAME_TRUNCATION_LENGTH)
    activity_titles = message.scan(/<strong>(.*?)<\/strong>/)
    activity_titles.each do |activity_title|
      activity_title = activity_title[0]
      closing = activity_title.index('</a>')
      unless closing.nil?
        ind = activity_title.index('<img')
        ind_temp = activity_title.index('<span')
        ind = ind_temp if ind.nil? || ind > ind_temp
      end
      temp = len
      while !ind.nil? && !closing.nil? && ind < temp
        stripped = strip_tags(activity_title[ind...closing]).length
        temp += (activity_title[ind...closing + TAGS_LENGTH]).length - stripped
        len = temp + TRUNCATE_OFFSET + TAGS_LENGTH if len <= closing
        closing_temp = closing + 1
        closing = activity_title.index('</a>', closing_temp)
        unless closing.nil?
          ind = activity_title.index('<img', closing_temp)
          ind_temp = activity_title.index('<span', closing_temp)
          ind = ind_temp if ind.nil? || ind > ind_temp
        end
      end
      len = activity_title.length if len > activity_title.length &&
                                     len != Constants::NAME_TRUNCATION_LENGTH
      if activity_title.length > len
        title = "<div class='modal-tooltip'>
                   #{truncate(activity_title, length: len, escape: false)}
                   <span class='modal-tooltiptext'>
                     #{activity_title}
                   </span>
                 </div>"
      else
        title = truncate(activity_title, length: len, escape: false)
      end
      message = message.gsub(/#{Regexp.escape(activity_title)}/, title)
    end
    sanitize_input(message) if message
  end

  def days_since_1970(dt)
    dt.to_i / 86400
  end
end
