# frozen_string_literal: true

module AutomationObservers
  class AllMyModulesDoneAutomationObserver
    def initialize(experiment, user)
      @user = user
      @experiment = experiment
    end

    def call
      return unless @experiment.team.settings.dig('team_automation_settings', 'all_tasks_done')
      return unless @experiment.started?
      return unless @experiment.my_modules.active.joins(:my_module_status).where.not(my_module_status: MyModuleStatusFlow.first.final_status).none?

      @experiment.update!(status: :done)

      Activities::CreateActivityService
        .call(activity_type: :automation_experiment_status_changed,
              owner: @user,
              team: @experiment.team,
              project: @experiment.project,
              subject: @experiment,
              message_items: {
                experiment: @experiment.id,
                experiment_status_old: I18n.t('experiments.table.column.status.in_progress'),
                experiment_status_new: I18n.t("experiments.table.column.status.#{@experiment.status}")
              })
    end
  end
end
