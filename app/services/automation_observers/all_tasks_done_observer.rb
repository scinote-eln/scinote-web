# frozen_string_literal: true

module AutomationObservers
  class AllTasksDoneObserver < BaseObserver
    def self.on_update(my_module, user)
      return unless Current.team.settings.dig('team_automation_settings', 'experiments', 'experiment_status_done', 'on_all_tasks_done')
      return if my_module.experiment.done?
      return unless my_module.experiment.my_modules.active.exists?
      return unless my_module.experiment.my_modules.active.joins(:my_module_status).where.not(my_module_status: MyModuleStatusFlow.first.final_status).none?

      experiment = my_module.experiment
      experiment.update!(status: :done, last_modified_by: user)

      Activities::CreateActivityService
        .call(activity_type: :automation_experiment_status_changed,
              owner: user,
              team: experiment.team,
              project: experiment.project,
              subject: experiment,
              message_items: {
                experiment: experiment.id,
                experiment_status_old: I18n.t("experiments.table.column.status.#{experiment.status_was}"),
                experiment_status_new: I18n.t("experiments.table.column.status.#{experiment.status}")
              })
    end
  end
end
