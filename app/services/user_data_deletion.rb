class UserDataDeletion
  def self.delete_team_data(team)
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    Step.skip_callback(:destroy, :after, :cascade_after_destroy)
    team.transaction do
      # Destroy tiny_mce_assets
      if team.tiny_mce_assets.present?
        team.tiny_mce_assets.each do |tiny_mce_asset|
          paperclip_file_destroy(tiny_mce_asset) if tiny_mce_asset.image.exists?
        end
      end
      team.repositories.each do |repository|
        repository.repository_rows.find_each do |repository_row|
          # Destroy repository_cell assets
          repository_row
            .repository_cells
            .where(value_type: 'RepositoryAssetValue').each do |repository_cell|
            next unless repository_cell.value.asset.file.exists?
            paperclip_file_destroy(repository_cell.value.asset)
          end
        end
        repository.destroy
      end
      team.projects.each do |project|
        project.reports.destroy_all
        project.activities.destroy_all
        project.experiments.each do |experiment|
          experiment.my_modules.each do |my_module|
            # Destroy result assets
            my_module.results.each do |result|
              result.result_table.delete if result.result_table.present?
              result.table.delete if result.table.present?
              next unless result.asset && result.asset.file.exists?
              paperclip_file_destroy(result.asset)
            end
            my_module.activities.destroy_all
            my_module.inputs.destroy_all
            my_module.outputs.destroy_all
            my_module.results.destroy_all
            my_module.my_module_tags.destroy_all
            my_module.task_comments.destroy_all
            my_module.my_module_repository_rows.destroy_all
            my_module.user_my_modules.destroy_all
            my_module.report_elements.destroy_all
            my_module.sample_my_modules.destroy_all
            my_module.protocols.each { |p| p.update_attributes(parent_id: nil) }
            my_module.protocols.each do |protocol|
              destroy_protocol(protocol)
            end
            my_module.delete
          end
          # Destroy workflow image
          if experiment.workflowimg.exists?
            experiment.workflowimg.clear(:original)
          end
          experiment.activities.destroy_all
          experiment.report_elements.destroy_all
          experiment.my_module_groups.delete_all
          experiment.delete
        end
        project.user_projects.destroy_all
        project.tags.destroy_all
        project.project_comments.destroy_all
        project.report_elements.destroy_all

        project.delete
      end
      team.protocols.each { |p| p.update_attributes(parent_id: nil) }
      team.protocols.where(my_module: nil).each do |protocol|
        destroy_protocol(protocol)
      end
      team.samples.destroy_all
      team.samples_tables.destroy_all
      team.sample_groups.destroy_all
      team.sample_types.destroy_all
      team.custom_fields.destroy_all
      team.protocol_keywords.destroy_all
      team.user_teams.delete_all
      User.where(current_team_id: team).each do |user|
        user.update(current_team_id: nil)
      end
      team.reports.destroy_all
      team.destroy!
      # raise ActiveRecord::Rollback
    end
    Step.set_callback(:destroy, :after, :cascade_after_destroy)
  end

  def self.destroy_protocol(protocol)
    protocol.steps.each do |step|
      # Destroy step assets
      if step.assets.present?
        step.assets.each do |asset|
          next unless asset.file.present?
          paperclip_file_destroy(asset)
        end
      end
      # Destroy step
      step.tables.destroy_all
      step.step_tables.delete_all
      step.report_elements.destroy_all
      step.step_comments.destroy_all
      step.step_assets.destroy_all
      step.checklists.destroy_all
      step.assets.destroy_all
      step.tiny_mce_assets.destroy_all
      step.delete
    end
    # Destroy protocol
    protocol.protocol_protocol_keywords.destroy_all
    protocol.protocol_keywords.destroy_all
    protocol.delete
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
    asset.save!
    asset.destroy!
  end
end
