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
      RepositoryLedgerRecord.includes(:user, :repository_row)
                            .where(repository_row: { id: row_ids })
                            .joins('LEFT OUTER JOIN my_module_repository_rows ON
                              repository_ledger_records.reference_id = my_module_repository_rows.id')
                            .joins('LEFT OUTER JOIN my_modules ON
                              my_modules.id = my_module_repository_rows.my_module_id')
                            .joins('LEFT OUTER JOIN experiments ON experiments.id = my_modules.experiment_id')
                            .joins('LEFT OUTER JOIN projects ON projects.id = experiments.project_id')
                            .joins('LEFT OUTER JOIN teams ON teams.id = projects.team_id')
                            .order('repository_row.created_at, repository_ledger_records.created_at')
                            .select('repository_ledger_records.*,
                                my_modules.id AS module_id, my_modules.name AS module_name,
                                projects.name AS project_name, teams.name AS team_name,
                                experiments.name AS experiment_name')
    # rubocop:disable Metrics/BlockLength
    repository_ledger_records.each do |record|
      consumption_type = record.reference_type == 'MyModuleRepositoryRow' ? 'Task' : 'Inventory'

      if record.amount.positive?
        added_amount = record.amount.to_d
        added_amount_unit = record.unit
      else
        consumed_amount = record.amount.abs.to_d
        consumed_amount_unit = record.unit
      end

      breadcrumbs_data = Array.new(4, '')

      row_data = [
        consumption_type,
        record.repository_row.name,
        record.repository_row.code,
        consumed_amount,
        consumed_amount_unit,
        added_amount,
        added_amount_unit,
        record.user.full_name,
        record.created_at.strftime(record.user.date_format),
        record.team_name,
        record.unit,
        record.balance.to_d
      ]

      if consumption_type == 'Task'
        breadcrumbs_data = [
          record.project_name,
          record.experiment_name,
          record.module_name,
          "#{MyModule::ID_PREFIX}#{record.module_id}"
        ]
      end

      row_data.insert(10, *breadcrumbs_data)
      data << row_data
    end
    # rubocop:enable Metrics/BlockLength
    data
  end
end
