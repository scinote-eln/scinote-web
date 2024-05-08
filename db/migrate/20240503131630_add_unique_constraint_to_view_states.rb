# frozen_string_literal: true

class AddUniqueConstraintToViewStates < ActiveRecord::Migration[7.0]
  def up
    # delete the duplicates
    execute 'WITH uniq AS
      (SELECT DISTINCT ON (user_id, viewable_id, viewable_type) * FROM view_states)
      DELETE FROM view_states WHERE view_states.id NOT IN
        (SELECT id FROM uniq)'

    # add index
    add_index :view_states, %i(user_id viewable_id viewable_type), unique: true
  end

  def down
    remove_index :view_states, columns: %i(user_id viewable_id viewable_type)
  end
end
