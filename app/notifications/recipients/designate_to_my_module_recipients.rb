# frozen_string_literal: true

module Recipients
  class DesignateToMyModuleRecipients < MyModuleDesignatedRecipients
    private

    def activity_recipients
      activity = Activity.find(@params[:activity_id])
      user = User.find_by(id: activity.values.dig('message_items', 'user_target', 'id'))

      return [] if user.id == activity.owner_id

      [user]
    end
  end
end

