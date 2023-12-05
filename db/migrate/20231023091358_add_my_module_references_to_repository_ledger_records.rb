# frozen_string_literal: true

class AddMyModuleReferencesToRepositoryLedgerRecords < ActiveRecord::Migration[7.0]
  def up
    add_column :repository_ledger_records, :my_module_references, :jsonb

    RepositoryLedgerRecord
      .joins(
        "INNER JOIN my_module_repository_rows
        ON my_module_repository_rows.id = repository_ledger_records.reference_id
        AND repository_ledger_records.reference_type = 'MyModuleRepositoryRow'
        INNER JOIN my_modules ON my_modules.id = my_module_repository_rows.my_module_id
        INNER JOIN experiments ON experiments.id = my_modules.experiment_id
        INNER JOIN projects ON projects.id = experiments.project_id
        INNER JOIN teams ON teams.id = projects.team_id"
      ).select(
        'repository_ledger_records.*, my_modules.id AS my_module_id, experiments.id AS experiment_id,' \
        'projects.id AS project_id, teams.id AS team_id '
      ).find_each do |ledger_record|
      ledger_record.update!(
        my_module_references: {
          my_module_id: ledger_record.my_module_id,
          experiment_id: ledger_record.experiment_id,
          project_id: ledger_record.project_id,
          team_id: ledger_record.team_id
        }
      )
    end
  end

  def down
    remove_column :repository_ledger_records, :my_module_references
  end
end
