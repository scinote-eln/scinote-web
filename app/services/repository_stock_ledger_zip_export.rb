# frozen_string_literal: true

require 'csv'

module RepositoryStockLedgerZipExport
  COLUMNS = %w(
    consumption_type
    item_name
    item_id
    consumed_amount
    consumed_amount_unit
    added_amount
    added_amount_unit
    consumed_by
    consumed_on
    team
    project
    experiment
    task
    task_id
    stock_amount_balance
    stock_balance_unit
  ).freeze

  def self.generate_zip(row_ids, user_id)
    rows = generate_data(row_ids)

    zip = ZipExport.create(user_id: user_id)
    zip.generate_exportable_zip(
      user_id,
      to_csv(rows),
      :repositories
    )
  end

  def self.to_csv(rows)
    csv_header = COLUMNS.map { |col| I18n.t("repository_stock_values.stock_export.headers.#{col}") }

    CSV.generate do |csv|
      csv << csv_header
      rows.each do |row|
        csv << row
      end
    end
  end

  def self.generate_data(row_ids)
    data = []
    repository_rows =
      RepositoryRow.where(id: row_ids)
                   .joins(repository_stock_value: [{ repository_ledger_records: :user }])
                   .joins('LEFT OUTER JOIN repositories ON repository_ledger_records.reference_id = repositories.id')
                   .joins('LEFT OUTER JOIN my_module_repository_rows ON
                     repository_ledger_records.reference_id = my_module_repository_rows.id')
                   .joins('LEFT OUTER JOIN my_modules ON my_modules.id = my_module_repository_rows.my_module_id')
                   .joins('LEFT OUTER JOIN experiments ON experiments.id = my_modules.experiment_id')
                   .joins('LEFT OUTER JOIN projects ON projects.id = experiments.project_id')
                   .joins('LEFT OUTER JOIN teams ON teams.id = projects.team_id')
                   .order('repository_rows.created_at, record_created_at')
                   .select('repository_rows.*, repository_ledger_records.created_at AS record_created_at,
                    repository_ledger_records.reference_type AS record_reference_type,
                    repository_ledger_records.amount AS record_amount,
                    repository_ledger_records.balance AS record_balance,
                    repository_ledger_records.unit AS record_unit,
                    users.full_name AS full_name, users.settings AS user_settings,
                    my_modules.id AS module_code, my_modules.name AS module_name,
                    projects.name AS project_name, teams.name AS team_name,
                    experiments.name AS experiment_name')

    previous_balance = nil
    previous_row_id = nil
    # rubocop:disable Metrics/BlockLength
    repository_rows.find_each do |row|
      action_type =
        previous_row_id == row.id && previous_balance && row.record_balance < previous_balance ? 'reduced' : 'added'
      consumption_type = row.record_reference_type == 'MyModuleRepositoryRow' ? 'Task' : 'Inventory'

      if action_type == 'reduced'
        consumed_amount = row.record_amount.abs
        consumed_amount_unit = row.record_unit
      else
        added_amount = row.record_amount
        added_amount_unit = row.record_unit
      end

      row_data = [
        consumption_type,
        row.name,
        row.code,
        consumed_amount,
        consumed_amount_unit,
        added_amount,
        added_amount_unit,
        row.full_name,
        row.record_created_at.strftime(JSON.parse(row.user_settings)['date_format']),
        row.team_name,
        row.project_name,
        row.experiment_name,
        row.module_name,
        "TA#{row.module_code}",
        row.record_balance,
        row.record_unit
      ]

      data << row_data
      previous_balance = row.record_balance
      previous_row_id = row.id
    end
    # rubocop:enable Metrics/BlockLength
    data
  end
end
