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
    repository_ledger_records =
      RepositoryLedgerRecord.joins([{ repository_stock_value: { repository_cell: :repository_row } }, :user])
                            .where("repository_rows.id IN (#{row_ids.split.join(',')})")
                            .joins('LEFT OUTER JOIN repositories ON
                              repository_ledger_records.reference_id = repositories.id')
                            .joins('LEFT OUTER JOIN my_module_repository_rows ON
                              repository_ledger_records.reference_id = my_module_repository_rows.id')
                            .joins('LEFT OUTER JOIN my_modules ON
                              my_modules.id = my_module_repository_rows.my_module_id')
                            .joins('LEFT OUTER JOIN experiments ON experiments.id = my_modules.experiment_id')
                            .joins('LEFT OUTER JOIN projects ON projects.id = experiments.project_id')
                            .joins('LEFT OUTER JOIN teams ON teams.id = projects.team_id')
                            .order('row_created_at, repository_ledger_records.created_at')
                            .select('repository_ledger_records.*,
                              repository_rows.created_at AS row_created_at,
                              repository_rows.id AS repository_id,
                              repository_rows.name AS repository_name,
                              users.full_name AS full_name, users.settings AS user_settings,
                              my_modules.id AS module_id, my_modules.name AS module_name,
                              projects.name AS project_name, teams.name AS team_name,
                              experiments.name AS experiment_name')

    previous_balance = nil
    previous_row_id = nil
    # rubocop:disable Metrics/BlockLength
    repository_ledger_records.each do |record|
      action_type = if previous_row_id == record.repository_id\
                        && previous_balance\
                        && record.balance < previous_balance
                      'reduced'
                    else
                      'added'
                    end

      consumption_type = record.reference_type == 'MyModuleRepositoryRow' ? 'Task' : 'Inventory'

      if action_type == 'reduced'
        consumed_amount = record.amount.abs
        consumed_amount_unit = record.unit
      else
        added_amount = record.amount
        added_amount_unit = record.unit
      end

      row_data = [
        consumption_type,
        record.repository_name,
        "IT#{record.repository_id}",
        consumed_amount,
        consumed_amount_unit,
        added_amount,
        added_amount_unit,
        record.full_name,
        record.created_at.strftime(JSON.parse(record.user_settings)['date_format']),
        record.team_name,
        record.project_name,
        record.experiment_name,
        record.module_name,
        "TA#{record.module_id}",
        record.unit,
        record.balance
      ]

      data << row_data
      previous_balance = record.balance
      previous_row_id = record.repository_id
    end
    # rubocop:enable Metrics/BlockLength
    data
  end
end
