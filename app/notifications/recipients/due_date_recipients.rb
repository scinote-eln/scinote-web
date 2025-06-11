# frozen_string_literal: true

module Recipients
  class DueDateRecipients
    def initialize(params)
      @params = params
    end

    def recipients
      record, permission = if @params[:experiment_id].present?
                             [Experiment.find_by(id: @params[:experiment_id]), ExperimentPermissions::MANAGE]
                           elsif @params[:project_id].present?
                             [Project.find_by(id: @params[:project_id]), ProjectPermissions::MANAGE]
                           end
      return User.none unless record

      User.where(id: record.user_assignments
                           .joins(:user_role)
                           .where('? = ANY(user_roles.permissions)', permission)
                           .select(:user_id))
    end
  end
end
