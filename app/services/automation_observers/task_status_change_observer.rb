# frozen_string_literal: true

module AutomationObservers
  class TaskStatusChangeObserver < BaseObserver
    def self.on_update(my_module, user)
      return unless Current.team.settings.dig('team_automation_settings', 'experiments', 'experiment_status_in_progress', 'on_task_in_progress')
      return unless my_module.saved_change_to_my_module_status_id? && !my_module.my_module_status.initial_status?
      return unless my_module.experiment.not_started?

      experiment = my_module.experiment
      experiment.update!(status: :in_progress, last_modified_by: user)

      Activities::CreateActivityService
        .call(activity_type: :automation_experiment_status_changed,
              owner: user,
              team: experiment.team,
              project: experiment.project,
              subject: experiment,
              message_items: {
                experiment: experiment.id,
                experiment_status_old: I18n.t('experiments.table.column.status.not_started'),
                experiment_status_new: I18n.t("experiments.table.column.status.#{experiment.status}")
              })
    end
  end
end
