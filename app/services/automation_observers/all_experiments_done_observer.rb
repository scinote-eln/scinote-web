# frozen_string_literal: true

module AutomationObservers
  class AllExperimentsDoneObserver < BaseObserver
    def self.on_update(experiment, user)
      return unless Current.team.settings.dig('team_automation_settings', 'projects', 'project_status_done', 'on_all_experiments_done')

      project = experiment.project

      return if project.done?
      return unless project.experiments.active.exists?
      return if project.experiments.active.where.not(id: project.experiments.active.done).exists?

      project.update!(status: :done, last_modified_by: user)

      Activities::CreateActivityService
        .call(activity_type: :automation_project_status_changed,
              owner: user,
              team: project.team,
              subject: project,
              message_items: {
                project: project.id,
                project_status_old: I18n.t("experiments.table.column.status.#{project.status_was}"),
                project_status_new: I18n.t("experiments.table.column.status.#{project.status}")
              })
    end
  end
end
