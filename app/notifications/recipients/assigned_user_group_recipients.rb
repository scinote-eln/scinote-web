# frozen_string_literal: true

module Recipients
  class AssignedUserGroupRecipients
    def initialize(params)
      @params = params
    end

    def recipients
      activity = Activity.find(@params[:activity_id])
      UserGroup.find_by(id: activity.values.dig('message_items', 'user_group', 'id'))&.users
    end
  end
end
