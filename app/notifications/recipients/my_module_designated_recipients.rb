# frozen_string_literal: true

class Recipients::MyModuleDesignatedRecipients
  def initialize(params)
    @params = params
  end

  def recipients
    if @params[:activity_id]
      activity_recipients
    else
      # other recipients
    end
  end

  private

  def activity_recipients
    activity = Activity.find(@params[:activity_id])
    case activity.subject_type
    when 'MyModule'
      users = activity.subject.designated_users
    when 'Protocol', 'Result'
      users = activity.subject.my_module.designated_users
    when 'Step'
      users = activity.subject.protocol.my_module.designated_users
    end

    users.where.not(id: activity.owner_id)
  end
end
