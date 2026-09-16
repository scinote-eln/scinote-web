# frozen_string_literal: true

class CreateAnalyticalReports < ActiveRecord::Migration[7.2]
  def up
    remove_column :report_templates, :generating_report

    create_table :analytical_reports do |t|
      t.string :name
      t.column :generating_status, :integer, null: false, default: 0
      t.references :reference, polymorphic: true, index: true
      t.references :report_template, index: true, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    execute <<-SQL.squish
      WITH inserted AS (
        INSERT INTO analytical_reports (name, reference_type, reference_id, created_at, updated_at)
        SELECT name, 'MyModule', my_module_id, created_at, updated_at
        FROM my_module_reports
        RETURNING id, reference_id, created_at
      )
      INSERT INTO active_storage_attachments (name, record_type, record_id, blob_id, created_at)
      SELECT asa.name, 'AnalyticalReport', inserted.id, asa.blob_id, asa.created_at
      FROM active_storage_attachments asa
      JOIN my_module_reports mmr ON mmr.id = asa.record_id AND asa.record_type = 'MyModuleReport' AND asa.name = 'report'
      JOIN inserted ON inserted.reference_id = mmr.my_module_id AND inserted.created_at = mmr.created_at
    SQL

    execute <<-SQL.squish
      DELETE FROM active_storage_attachments WHERE record_type = 'MyModuleReport' AND name = 'report'
    SQL
    drop_table :my_module_reports
  end

  def down
    add_column :report_templates, :generating_report, :boolean, default: false, null: false

    create_table :my_module_reports do |t|
      t.string :name
      t.references :my_module, index: true, foreign_key: true
      t.timestamps
    end

    execute <<-SQL.squish
      WITH inserted AS (
        INSERT INTO my_module_reports (name, my_module_id, created_at, updated_at)
        SELECT name, reference_id, created_at, updated_at
        FROM analytical_reports
        WHERE reference_type = 'MyModule'
        RETURNING id, my_module_id, created_at
      )
      INSERT INTO active_storage_attachments (name, record_type, record_id, blob_id, created_at)
      SELECT asa.name, 'MyModuleReport', inserted.id, asa.blob_id, asa.created_at
      FROM active_storage_attachments asa
      JOIN analytical_reports ar
        ON ar.reference_type = 'MyModule'
      AND asa.record_type = 'AnalyticalReport'
      AND asa.record_id = ar.id
      AND asa.name = 'report'
      JOIN inserted ON inserted.my_module_id = ar.reference_id
                  AND inserted.created_at = ar.created_at
    SQL

    execute <<-SQL.squish
      DELETE FROM active_storage_attachments
      WHERE record_type = 'AnalyticalReport' AND name = 'report'
    SQL

    drop_table :analytical_reports
  end
end
