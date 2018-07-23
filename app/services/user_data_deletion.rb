class UserDataDeletion
  def self.delete_team_data(team)
    team.transaction(isolation: :serializable) do
      team.projects.each do |project|
        project.user_projects.destroy_all
        project.activities.destroy_all
        project.tags.destroy_all
        project.experiments.destroy_all
        project.destroy
      end
      team.samples.destroy_all
      team.sample_groups.destroy_all
      team.sample_types.destroy_all
      team.custom_fields.destroy_all
      team.user_teams.destroy_all
      User.where(current_team_id: team).each do |user|
        user.update(current_team_id: nil)
      end
      team.destroy!
    end
  end

  def self.destroy_notifications(user)
    # Find all notifications where user is the only reference
    # on the notification, and destroy all such notifications
    # (user_notifications are destroyed when notification is
    # destroyed). We try to do this efficiently (hence in_groups_of).
    nids_all = user.notifications.pluck(:id)
    nids_all.in_groups_of(1000, false) do |nids|
      Notification
        .where(id: nids)
        .joins(:user_notifications)
        .group('notifications.id')
        .having('count(notification_id) <= 1')
        .destroy_all
    end
    # Now, simply destroy all user notification relations left
    user.user_notifications.destroy_all
  end
end
