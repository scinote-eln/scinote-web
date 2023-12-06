# frozen_string_literal: true

class Recipients::AssignedGroupRecipients
  def initialize(params)
    @params = params
  end

  def recipients
    activity = Activity.find(@params[:activity_id])
    project = activity.subject
    project.team.users.where.not(id: project.user_assignments.where(assigned: 'manually').select(:user_id))
  end
end
