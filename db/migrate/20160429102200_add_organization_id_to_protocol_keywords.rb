class AddOrganizationIdToProtocolKeywords < ActiveRecord::Migration[4.2]
  def up
    add_column :protocol_keywords, :team_id, :integer
    add_foreign_key :protocol_keywords, :teams, column: :team_id
    add_index :protocol_keywords, :team_id

    # Set team to all protocol keywords
    ProtocolKeyword.find_each do |kw|
      if kw.protocols.count == 0
        kw.destroy
      else
        kw.update(team_id: kw.protocols.first.team_id)
      end
    end

    # Finally, set the column to null = false
    change_column_null :protocol_keywords, :team_id, false
  end

  def down
    remove_index :protocol_keywords, column: :team_id
    remove_foreign_key :protocol_keywords, column: :team_id
    remove_column :protocol_keywords, :team_id
  end
end
