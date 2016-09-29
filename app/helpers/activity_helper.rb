module ActivityHelper
  def activity_truncate(message, len = NAME_TRUNCATION_LENGTH)
    activity_title = message.match(/<strong>(.*?)<\/strong>/)[1]
    if activity_title.length > NAME_TRUNCATION_LENGTH
      title = "<div class='modal-tooltip'>#{truncate(activity_title, length: len)}
		<span class='modal-tooltiptext'>#{activity_title}</span></div>"
    else
      title = truncate(activity_title, length: len)
    end
    message = message.gsub(/#{activity_title}/, title )
    message.html_safe if message
  end
end
