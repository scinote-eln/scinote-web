# frozen_string_literal: true

module AutomationObservers
  class ExperimentStatusChangeAutomationObserver
    def initialize(experiment, user)
      @experiment = experiment
      @user = user
      @project = @experiment.project
    end

    def call
      return unless @project.team.settings.dig('team_automation_settings', 'experiment_moves_from_not_started_to_in_progress')
      return unless @project.not_started?
      return if @experiment.not_started?

      @project.update!(status: :in_progress)
      Activities::CreateActivityService
        .call(activity_type: :automation_project_status_changed,
              owner: @user,
              team: @project.team,
              subject: @project,
              message_items: {
                project: @project.id,
                project_status_old: I18n.t('experiments.table.column.status.not_started'),
                project_status_new: I18n.t("experiments.table.column.status.#{@project.status}")
              })
    end
  end
end
