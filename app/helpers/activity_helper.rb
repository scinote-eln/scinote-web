module ActivityHelper
  def activity_truncate(message, len = 20)
    activity_title = message.match(/<strong>(.*?)<\/strong>/)[1]
    if activity_title.length > 20
      title = "<div class='modal-tooltip'>#{truncate(activity_title, length: len)}
		<span class='modal-tooltiptext'>#{activity_title}</span></div>"
    else
      title = truncate(activity_title, length: len)
    end
    message = message.gsub(/#{activity_title}/, title )
    message.html_safe if message
  end
end
