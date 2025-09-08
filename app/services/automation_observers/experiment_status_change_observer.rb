# frozen_string_literal: true

module AutomationObservers
  class ExperimentStatusChangeObserver < BaseObserver
    def self.on_update(experiment, user)
      return unless Current.team.settings.dig('team_automation_settings', 'projects', 'project_status_in_progress', 'on_experiment_in_progress')
      return unless experiment.status_moved_forward? ||
                    experiment.saved_change_to_project_id ||
                    (experiment.saved_change_to_archived && !experiment.archived)

      project = experiment.project

      return unless project.not_started?
      return if experiment.not_started?

      project.update!(status: :in_progress, last_modified_by: user)

      Activities::CreateActivityService
        .call(activity_type: :automation_project_status_changed,
              owner: user,
              team: project.team,
              subject: project,
              message_items: {
                project: project.id,
                project_status_old: I18n.t('experiments.table.column.status.not_started'),
                project_status_new: I18n.t("experiments.table.column.status.#{project.status}")
              })
    end
  end
end
