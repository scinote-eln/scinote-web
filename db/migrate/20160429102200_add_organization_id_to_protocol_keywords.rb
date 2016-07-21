class AddOrganizationIdToProtocolKeywords < ActiveRecord::Migration
  def up
    add_column :protocol_keywords, :organization_id, :integer
    add_foreign_key :protocol_keywords, :organizations, column: :organization_id
    add_index :protocol_keywords, :organization_id

    # Set organization to all protocol keywords
    ProtocolKeyword.find_each do |kw|
      if kw.protocols.count == 0
        kw.destroy
      else
        kw.update(organization_id: kw.protocols.first.organization_id)
      end
    end

    # Finally, set the column to null = false
    change_column_null :protocol_keywords, :organization_id, false
  end

  def down
    remove_index :protocol_keywords, column: :organization_id
    remove_foreign_key :protocol_keywords, column: :organization_id
    remove_column :protocol_keywords, :organization_id
  end
end
