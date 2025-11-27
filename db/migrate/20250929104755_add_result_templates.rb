# frozen_string_literal: true

class AddResultTemplates < ActiveRecord::Migration[7.2]
  def up
    change_table :results, bulk: true do |t|
      t.string :type
      t.references :protocol, null: true
    end

    change_column_null :results, :my_module_id, true

    execute "UPDATE \"results\" SET \"type\" = 'Result'"

    execute <<~SQL.squish
      UPDATE activities
      SET subject_type = 'ResultBase'
      WHERE subject_type = 'Result'
    SQL
  end

  def down
    change_table :results, bulk: true do |t|
      t.remove :type
      t.remove_references :protocol
    end

    change_column_null :results, :my_module_id, false

    # rubocop:disable Rails/SkipsModelValidations
    Activity.where(subject_type: 'ResultBase').find_each do |activity|
      next if activity.project.blank?

      activity.update_columns(subject_type: 'Result')
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
