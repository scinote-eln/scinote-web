class UserDataDeletion
  def self.delete_team_data(team)
    team.transaction(isolation: :serializable) do
      # Destroy tiny_mce_assets
      if team.tiny_mce_assets.present?
        team.tiny_mce_assets.each do |tiny_mce_asset|
          paperclip_file_destroy(tiny_mce_asset)
        end
      end

      # Destroy step assets
      team.protocols.each do |protocol|
        protocol.steps.each do |step|
          next unless step.assets.present?
          step.assets.each do |asset|
            paperclip_file_destroy(asset)
          end
        end
      end

      # Destroy repository_cell assets
      team.repositories.each do |repository|
        repository.repository_rows.each do |repository_row|
          repository_row.repository_cells.each do |repository_cell|
            next unless repository_cell.value_type == 'RepositoryAssetValue'
            paperclip_file_destroy(repository_cell.value.asset)
          end
        end
      end

      team.projects.each do |project|
        # Destroy result assets
        project.experiments.each do |experiment|
          experiment.my_modules.each do |my_module|
            my_module.results.each do |result|
              next unless result.asset.present?
              paperclip_file_destroy(result.asset)
            end
          end
        end
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

  # Workaround for Paperclip preserve_files option, to delete files anyway;
  # if you call #clear with a list of styles to delete,
  # it'll call #queue_some_for_delete, which doesn't check :preserve_files.
  def self.paperclip_file_destroy(asset)
    if asset.class.name == 'TinyMceAsset'
      all_styles = asset.image.styles.keys.map do |key|
        asset.image.styles[key].name
      end << :original
      asset.image.clear(*all_styles)
    else
      all_styles = asset.file.styles.keys.map do |key|
        asset.file.styles[key].name
      end << :original
      asset.file.clear(*all_styles)
    end
    asset.save
    asset.destroy!
  end
end
