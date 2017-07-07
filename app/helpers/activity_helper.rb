module ActivityHelper
  def activity_truncate(message, len = Constants::NAME_TRUNCATION_LENGTH)
    activity_titles = message.scan(/<strong>(.*?)<\/strong>/)
    activity_titles.each do |activity_title|
      activity_title = activity_title[0]
      unless activity_title.length == smart_annotation_parser(activity_title)
             .length
        temp = activity_title.index('[')
        while  !temp.nil? && temp < len
          if activity_title[temp + 1] == '#' || activity_title[temp + 1] == '@'
            last_sa = activity_title.index(']', temp)
          end
          temp = activity_title.index('[', last_sa)
          len = last_sa if last_sa > len
        end
        len += 4
      end
      if activity_title.length > len
        title = "<div class='modal-tooltip'>
                   #{truncate(activity_title, length: len)}
                   <span class='modal-tooltiptext'>
                     #{activity_title}
                   </span>
                 </div>"
      else
        title = truncate(activity_title, length: len)
      end
      message = smart_annotation_parser(message.gsub(/#{Regexp.escape(activity_title)}/, title))
    end
    sanitize_input(message) if message
  end

  def days_since_1970(dt)
    dt.to_i / 86400
  end
end
