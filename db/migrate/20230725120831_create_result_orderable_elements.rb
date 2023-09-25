# frozen_string_literal: true

class CreateResultOrderableElements < ActiveRecord::Migration[7.0]
  def up
    create_table :result_orderable_elements do |t|
      t.references :result, null: false, index: false, foreign_key: true
      t.integer :position, null: false
      t.references :orderable, polymorphic: true

      t.timestamps

      t.index %i(result_id position), unique: true
    end

    ActiveRecord::Base.connection.execute(
      'INSERT INTO ' \
      'result_orderable_elements(result_id, position, orderable_type, orderable_id, created_at, updated_at) ' \
      'SELECT result_id, 0, \'ResultText\', id, NOW(), NOW() FROM result_texts;'
    )

    ActiveRecord::Base.connection.execute(
      'INSERT INTO ' \
      'result_orderable_elements(result_id, position, orderable_type, orderable_id, created_at, updated_at) ' \
      'SELECT result_id, 0, \'ResultTable\', id, NOW(), NOW() FROM result_tables;'
    )
  end

  def down
    ResultOrderableElement.delete_all
    drop_table :result_orderable_elements
  end
end
