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

  def self.generate_zip(row_ids, current_user)
    rows = generate_data(row_ids)

    zip = ZipExport.create(user: current_user)
    zip.generate_exportable_zip(
      current_user,
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
    repository_rows = RepositoryRow.where(id: row_ids)
                                   .includes(
                                     repository_stock_value: {
                                       repository_ledger_records: [
                                         { repository_stock_value: :repository_stock_unit_item },
                                         :reference,
                                         :user
                                       ]
                                     }
                                   )
    # rubocop:disable Metrics/BlockLength
    repository_rows.each do |repository_row|
      previous_balance = nil
      next unless repository_row.repository_stock_value

      repository_row.repository_stock_value.repository_ledger_records.order(:created_at).each do |record|
        action_type = previous_balance && record.balance < previous_balance ? 'reduced' : 'added'
        consumption_type = record.reference_type == 'MyModuleRepositoryRow' ? 'Task' : 'Inventory'

        if action_type == 'reduced'
          consumed_amount = record.amount.abs
          consumed_amount_unit = record.unit || record.repository_stock_value.repository_stock_unit_item.data
        else
          added_amount = record.amount
          added_amount_unit = record.unit || record.repository_stock_value.repository_stock_unit_item.data
        end

        row_data = [
          consumption_type,
          repository_row.name,
          "IT#{repository_row.id}",
          consumed_amount,
          consumed_amount_unit,
          added_amount,
          added_amount_unit,
          record.user.full_name,
          record.created_at.strftime(record.user.date_format),
          record.balance,
          record.repository_stock_value.repository_stock_unit_item.data
        ]
        breadcrumbs_data = Array.new(5, '')

        if consumption_type == 'Task'
          breadcrumbs_data = [
            record.reference.my_module.project.team.name,
            record.reference.my_module.project.name,
            record.reference.my_module.experiment.name,
            record.reference.my_module.name,
            "TA#{record.reference.my_module.id}"
          ]
        end

        row_data.insert(9, *breadcrumbs_data)
        data << row_data
        previous_balance = record.balance
      end
    end
    # rubocop:enable Metrics/BlockLength
    data
  end
end
