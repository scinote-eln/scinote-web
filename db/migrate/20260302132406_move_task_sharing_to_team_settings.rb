# frozen_string_literal: true

class MoveTaskSharingToTeamSettings < ActiveRecord::Migration[7.2]
  # rubocop:disable Rails/SkipsModelValidations
  def up
    Team.find_each do |team|
      team.update_column(:settings, team.settings.merge({ 'task_sharing_enabled' => team.attributes['shareable_links_enabled'],
                                                          'repository_deletion_enabled' => true,
                                                          'result_deletion_enabled' => true,
                                                          'protocol_steps_deletion_enabled' => true }))
    end

    remove_column :teams, :shareable_links_enabled
  end

  def down
    add_column :teams, :shareable_links_enabled, :boolean, null: false, default: false

    Team.find_each do |team|
      team.update_column(:shareable_links_enabled, team.settings['task_sharing_enabled'] || false)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
