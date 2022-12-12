# frozen_string_literal: true

class AddProtocolVersioning < ActiveRecord::Migration[6.1]
  def up
    change_table :protocols, bulk: true do |t|
      t.boolean :archived, default: false, null: false, index: true
      t.integer :version_number, default: 1
    end
    add_reference :protocols, :previous_version, index: true, foreign_key: { to_table: :protocols }
    execute(
      'UPDATE "protocols" SET "archived" = TRUE WHERE "protocols"."protocol_type" = 4;'
    )
    execute(
      'UPDATE "protocols" SET "protocol_type" = 2 WHERE "protocols"."protocol_type" IN (3, 4);'
    )
  end

  def down
    execute(
      'UPDATE "protocols" SET "protocol_type" = 4 WHERE "protocols"."protocol_type" = 2 AND '\
      '"protocols"."archived" = TRUE;'
    )
    remove_reference :protocols, :previous_version, index: true, foreign_key: { to_table: :protocols }
    change_table :protocols, bulk: true do |t|
      t.remove :version_number
      t.remove :archived
    end
  end
end
