# frozen_string_literal: true

class FixAndUpdateIndicesOnActivities < ActiveRecord::Migration[6.0]
  def up
    execute(
      "UPDATE activities " \
      "SET values = jsonb_set(values, '{\"message_items\", \"asset_name\", \"value_for\"}', '\"file_name\"') " \
      "WHERE values @> '{\"message_items\": {\"asset_name\": {\"value_for\": \"file_file_name\"}}}';"
    )
    add_index :activities, %i(created_at team_id), order: { created_at: :desc, team_id: :asc },
                                                   where: 'project_id IS NULL',
                                                   name: 'index_activities_on_created_at_and_team_id_and_no_project_id'
  end

  def down
    remove_index :activities, %i(created_at team_id)
  end
end
