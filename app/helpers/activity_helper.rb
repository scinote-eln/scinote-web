module ActivityHelper
  # constants for correct truncation length
  TAGS_LENGTH = 4
  TRUNCATE_OFFSET = 3
  def activity_truncate(message, len = Constants::NAME_TRUNCATION_LENGTH)
    activity_titles = message.scan(/<strong>(.*?)<\/strong>/)
    activity_titles.each do |activity_title|
      activity_title = activity_title[0]
      # find first closing tag of smart annotation
      closing_tag_sa = activity_title.index('</a>')
      unless closing_tag_sa.nil?
        opening_tag_sa = activity_title.index('<img')
        opening_temp = activity_title.index('<span')
        # depending on user/experiment set the first opening tag
        opening_tag_sa = opening_temp if opening_tag_sa.nil? ||
                                         opening_tag_sa > opening_temp
      end
      len_temp = len
      # check until we run out of smart annotations in message
      while !opening_tag_sa.nil? && !closing_tag_sa.nil? &&
            opening_tag_sa < len_temp
        stripped = strip_tags(activity_title[opening_tag_sa...closing_tag_sa])
                   .length
        len_temp += (activity_title[opening_tag_sa...closing_tag_sa +
                    TAGS_LENGTH]).length - stripped
        len = len_temp + TRUNCATE_OFFSET + TAGS_LENGTH if len <= closing_tag_sa
        closing_temp = closing_tag_sa + 1
        closing_tag_sa = activity_title.index('</a>', closing_temp)
        unless closing_tag_sa.nil?
          # find next smart annotation
          opening_tag_sa = activity_title.index('<img', closing_temp)
          opening_temp = activity_title.index('<span', closing_temp)
          # depending on user/experiment set the next opening tag
          opening_tag_sa = opening_temp if opening_tag_sa.nil? ||
                                           opening_tag_sa > opening_temp
        end
      end
      # adjust truncation length according to smart annotations length
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

  def calculate_previous_date(activities,
                              index,
                              previus_batch_last_activitiy_date)
    if index == 1 && !activities.first_page?
      return previus_batch_last_activitiy_date
    end
    activity = activities[index - 1]
    return activity.created_at.to_date if activity
    Date.new(1901, 1, 1)
  end
end
