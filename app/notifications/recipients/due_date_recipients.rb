# frozen_string_literal: true

module Recipients
  class DueDateRecipients
    def initialize(params)
      @params = params
    end

    def recipients
      if @params[:experiment_id].present?
        experiment = Experiment.find_by(id: @params[:experiment_id])
        User.where(id: experiment.user_assignments
                                 .joins(:user_role)
                                 .where('? = ANY(user_roles.permissions)',
                                        ExperimentPermissions::MANAGE).select(:user_id))
      end
    end
  end
end
