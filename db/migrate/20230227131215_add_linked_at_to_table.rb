# frozen_string_literal: true

class AddLinkedAtToTable < ActiveRecord::Migration[6.1]
  def up
    add_column :protocols, :linked_at, :datetime

    execute(
      'UPDATE protocols
       SET linked_at = act.activities_created_at
       FROM (SELECT MAX(activities.created_at) AS activities_created_at, MAX(activities.subject_id) AS subject_id
             FROM protocols
             LEFT JOIN activities ON activities.subject_id = protocols.id AND activities.subject_type=\'Protocol\'
             WHERE protocols.protocol_type = 1 AND activities.type_of = 46
             GROUP BY protocols.id) as act
       WHERE id = act.subject_id'
    )
  end

  def down
    remove_column :protocols, :linked_at
  end
end
