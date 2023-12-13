# frozen_string_literal: true

class Recipients::UserChangedRecipient
  def initialize(params)
    @params = params
  end

  def recipients
    activity = Activity.find(@params[:activity_id])
    User.where(id: activity.values.dig('message_items', 'user_changed', 'id'))
  end
end
