class UserDataDeletion
  def self.delete_team_data(team)
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    team.transaction do
      # Destroy tiny_mce_assets
      if team.tiny_mce_assets.present?
        team.tiny_mce_assets.each do |tiny_mce_asset|
          tiny_mce_asset.image.purge
          tiny_mce_asset.destroy!
        end
      end
      team.repositories.each do |repository|
        repository.repository_rows.find_each do |repository_row|
          # Destroy repository_cell assets
          repository_row
            .repository_cells
            .where(value_type: 'RepositoryAssetValue').each do |repository_cell|
            repository_cell.value.asset.file.purge
            repository_cell.value.asset.destroy!
          end
        end
        repository.destroy!
      end
      team.projects.each do |project|
        project.reports.destroy_all
        project.activities.destroy_all
        project.experiments.each do |experiment|
          experiment.my_modules.each do |my_module|
            # Destroy result assets
            my_module.results.each do |result|
              result.assets.each do |asset|
                asset.file.purge
                asset.destroy!
              end
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
            my_module.protocols.each { |p| p.update(parent_id: nil) }
            my_module.protocols.each do |protocol|
              destroy_protocol(protocol)
            end
            my_module.user_assignments.destroy_all
            my_module.destroy!
          end

          # Destroy workflow image
          experiment.workflowimg.purge

          experiment.activities.destroy_all
          experiment.report_elements.destroy_all
          experiment.my_module_groups.destroy_all
          experiment.user_assignments.destroy_all
          experiment.destroy!
        end
        project.tags.destroy_all
        project.project_comments.destroy_all
        project.report_elements.destroy_all
        project.user_assignments.destroy_all

        project.destroy!
      end
      team.repository_protocols.each do |protocol|
        destroy_protocol(protocol)
      end
      team.protocol_keywords.destroy_all
      User.where(current_team_id: team).each do |user|
        user.update(current_team_id: nil)
      end
      team.reports.destroy_all
      team.user_assignments.destroy_all
      team.destroy!
    end
  end

  def self.destroy_protocol(protocol)
    protocol.steps.each do |step|
      # Destroy step assets
      if step.assets.present?
        step.assets.each do |asset|
          asset.file.purge
          asset.destroy!
        end
      end
      # Destroy step
      step.skip_position_adjust = true
      step.tables.destroy_all
      step.step_tables.destroy_all
      step.step_texts.destroy_all
      step.report_elements.destroy_all
      step.step_comments.destroy_all
      step.step_assets.destroy_all
      step.checklists.destroy_all
      step.assets.destroy_all
      step.tiny_mce_assets.destroy_all
      step.destroy!
    end
    # Destroy protocol
    protocol.protocol_protocol_keywords.destroy_all
    protocol.protocol_keywords.destroy_all
    protocol.destroy!
  end

  def self.destroy_notifications(user)
    user.notifications.in_batches(of: 1000).destroy_all
  end
end
