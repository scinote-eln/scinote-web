# frozen_string_literal: true

class Recipients::DeletedCalendarEventRecipients
  def initialize(params)
    @params = params
  end

  def recipients
    User.where(id: Activity.find(@params[:activity_id]).message_items['participant_user_ids'].split(','))
  end
end
