# frozen_string_literal: true

class MigrateTagsFromProjectsToWorkspaces < ActiveRecord::Migration[7.2]
  def up
    add_reference :tags, :team, foreign_key: true, index: true
    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false, index: true
      t.references :created_by, foreign_key: { to_table: :users }
    end

    add_index :taggings, %i(taggable_type taggable_id tag_id), unique: true

    execute <<~SQL.squish
      INSERT INTO taggings (id, tag_id, taggable_type, taggable_id, created_by_id)
      SELECT id, tag_id, 'MyModule', my_module_id,  created_by_id
      FROM my_module_tags
    SQL

    execute <<~SQL.squish
      SELECT setval('taggings_id_seq', (SELECT MAX(id) FROM taggings));
    SQL

    execute <<~SQL.squish
      UPDATE tags
      SET team_id = projects.team_id
      FROM projects
      WHERE tags.project_id = projects.id
    SQL

    change_column_null :tags, :team_id, false
    remove_reference :tags, :project, index: true, foreign_key: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
