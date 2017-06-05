module ActivityHelper
  def activity_truncate(message, len = Constants::NAME_TRUNCATION_LENGTH)
    activity_titles = message.scan(/<strong>(.*?)<\/strong>/)
    activity_titles.each do |activity_title|
      activity_title = activity_title[0]
      if activity_title.length > Constants::NAME_TRUNCATION_LENGTH
        title = "<div class='modal-tooltip'>
                   #{truncate(activity_title, length: len)}
                   <span class='modal-tooltiptext'>
                     #{activity_title}
                   </span>
                 </div>"
      else
        title = truncate(activity_title, length: len)
      end
      message = message.gsub(/#{Regexp.escape(activity_title)}/, title)
    end
    sanitize_input(message) if message
  end

  def days_since_1970(dt)
    dt.to_i / 86400
  end
end
