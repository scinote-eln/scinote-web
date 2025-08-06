# frozen_string_literal: true

module AutomationObservers
  class AllExperimentsDoneAutomationObserver
    def initialize(project, user)
      @user = user
      @project = project
    end

    def call
      return unless @project.team.settings.dig('team_automation_settings', 'all_experiments_done')
      return unless @project.started?
      return if @project.experiments.active.where.not(id: @project.experiments.active.done).exists?

      @project.update!(status: :done)

      Activities::CreateActivityService
        .call(activity_type: :automation_project_status_changed,
              owner: @user,
              team: @project.team,
              subject: @project,
              message_items: {
                project: @project.id,
                project_status_old: I18n.t('experiments.table.column.status.in_progress'),
                project_status_new: I18n.t("experiments.table.column.status.#{@project.status}")
              })
    end
  end
end
