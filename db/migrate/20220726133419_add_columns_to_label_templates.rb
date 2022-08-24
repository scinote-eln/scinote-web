# frozen_string_literal: true

class AddColumnsToLabelTemplates < ActiveRecord::Migration[6.1]
  def up
    change_table :label_templates, bulk: true do |t|
      t.string :description
      t.string :format, null: false, default: 'ZPL'
      t.integer :last_modified_by_id
      t.integer :created_by_id
    end

    add_foreign_key :label_templates, :users, column: :last_modified_by_id
    add_foreign_key :label_templates, :users, column: :created_by_id
    add_index :label_templates, :last_modified_by_id
    add_index :label_templates, :created_by_id

    add_reference :label_templates, :team, index: true, foreign_key: true

    if Team.count.positive?
      # rubocop:disable Rails/SkipsModelValidations
      LabelTemplate.first.update_columns(
        created_by_id: Team.first.created_by_id,
        last_modified_by_id: Team.first.created_by_id,
        team_id: Team.first.id
      )
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def down
    remove_reference :label_templates, :team, index: true, foreign_key: true
    remove_index :label_templates, column: :last_modified_by_id
    remove_index :label_templates, column: :created_by_id
    remove_foreign_key :label_templates, :users, column: :last_modified_by_id
    remove_foreign_key :label_templates, :users, column: :created_by_id

    change_table :label_templates, bulk: true do |t|
      t.remove :description
      t.remove :format, null: false, default: 'ZPL'
      t.remove :last_modified_by_id
      t.remove :created_by_id
    end
  end
end
