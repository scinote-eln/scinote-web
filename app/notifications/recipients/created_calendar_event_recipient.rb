# frozen_string_literal: true

class Recipients::CreatedCalendarEventRecipient
  def initialize(params)
    @params = params
  end

  def recipients
    activity = Activity.find(@params[:activity_id])
    target_user_id = activity.message_items.dig('user_target', 'id')

    return User.none if target_user_id == activity.owner_id

    User.where(id: target_user_id)
  end
end
