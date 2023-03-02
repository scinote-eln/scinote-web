# frozen_string_literal: true

class AddProtocolVersioning < ActiveRecord::Migration[6.1]
  def up
    change_table :protocols, bulk: true do |t|
      t.integer :visibility, index: true, default: 0
      t.boolean :archived, default: false, null: false, index: true
      t.integer :version_number, default: 1
      t.string :version_comment
      t.references :default_public_user_role, foreign_key: { to_table: :user_roles }
      t.references :previous_version, index: true, foreign_key: { to_table: :protocols }
      t.references :last_modified_by, index: true, foreign_key: { to_table: :users }
      t.references :published_by, index: true, foreign_key: { to_table: :users }
    end

    execute(
      'UPDATE "protocols" SET "protocol_type" = 3, "archived" = TRUE WHERE "protocols"."protocol_type" = 4;'
    )
    execute(
      'UPDATE "protocols" SET "visibility" = 1 WHERE "protocols"."protocol_type" = 3;'
    )
    execute(
      'UPDATE "protocols" SET "protocol_type" = 2 ' \
      'WHERE "id" IN (' \
      'SELECT DISTINCT "protocols"."id" FROM "protocols" ' \
      'JOIN "protocols" "linked_children" ON "linked_children"."parent_id" = "protocols"."id" ' \
      'WHERE "protocols"."protocol_type" IN (2, 3)' \
      ');'
    )
    execute(
      'UPDATE "protocols" SET "protocol_type" = 3 ' \
      'WHERE "id" IN (' \
      'SELECT DISTINCT "protocols"."id" FROM "protocols" ' \
      'LEFT OUTER JOIN "protocols" "linked_children" ON "linked_children"."parent_id" = "protocols"."id" ' \
      'WHERE "protocols"."protocol_type" IN (2, 3) AND "linked_children"."id" IS NULL' \
      ');'
    )
    execute(
      'UPDATE "protocols" SET "published_on" = "created_at", "published_by_id" = "added_by_id" ' \
      'WHERE "protocols"."protocol_type" = 2 ' \
      'AND "protocols"."published_on" IS NULL;'
    )
  end

  def down
    execute(
      'UPDATE "protocols" SET "protocol_type" = 4 WHERE "protocols"."protocol_type" IN (2, 3, 4) AND ' \
      '"protocols"."archived" = TRUE;'
    )
    change_table :protocols, bulk: true do |t|
      t.remove_references :published_by
      t.remove_references :last_modified_by
      t.remove_references :previous_version
      t.remove_references :default_public_user_role
      t.remove :version_comment
      t.remove :version_number
      t.remove :archived
      t.remove :visibility
    end
  end
end
