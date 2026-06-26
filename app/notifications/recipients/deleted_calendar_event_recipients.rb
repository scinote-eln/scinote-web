# frozen_string_literal: true

class Recipients::DeletedCalendarEventRecipients
  def initialize(params)
    @params = params
  end

  def recipients
    activity = Activity.find(@params[:activity_id])
    user_ids = activity.message_items.dig('user_target', 'id') || activity.message_items['participant_user_ids']&.split(',')

    User.where(id: user_ids)
  end
end
