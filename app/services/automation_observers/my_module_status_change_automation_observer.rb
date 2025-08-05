# frozen_string_literal: true

module AutomationObservers
  class MyModuleStatusChangeAutomationObserver
    def initialize(my_module, user)
      @my_module = my_module
      @user = user
      @experiment = @my_module.experiment
    end

    def call
      return unless @my_module.team.settings.dig('team_automation_settings', 'task_moves_from_not_started_to_in_progress')
      return unless @experiment.not_started?
      return if @my_module.my_module_status.initial_status?

      @experiment.update!(status: :in_progress)

      Activities::CreateActivityService
        .call(activity_type: :automation_experiment_status_changed,
              owner: @user,
              team: @experiment.team,
              project: @experiment.project,
              subject: @experiment,
              message_items: {
                experiment: @experiment.id,
                experiment_status_old: I18n.t('experiments.table.column.status.not_started'),
                experiment_status_new: I18n.t("experiments.table.column.status.#{@experiment.status}")
              })
    end
  end
end
