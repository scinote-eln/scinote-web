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

  def self.to_csv(repository_row_ids)
    csv_header = COLUMNS.map { |col| I18n.t("repository_stock_values.stock_export.headers.#{col}") }
    repository_ledger_records = load_records(repository_row_ids)

    CSV.generate do |csv|
      csv << csv_header
      repository_ledger_records.each do |record|
        csv << generate_record_data(record)
      end
    end
  end

  class << self
    private

    def load_records(repository_row_ids)
      RepositoryLedgerRecord
        .joins(:repository_row)
        .preload(:user, repository_row: { repository: :team })
        .preload(my_module_repository_row: { my_module: { experiment: { project: :team } } })
        .where(repository_row: { id: repository_row_ids })
        .order(:created_at)
    end

    def generate_record_data(record)
      consumption_type = record.reference_type == 'MyModuleRepositoryRow' ? 'Task' : 'Inventory'

      if (consumption_type == 'Task' && record.amount.positive?) ||
         (consumption_type == 'Inventory' && record.amount.negative?)
        consumed_amount = record.amount.abs.to_d
        consumed_amount_unit = record.unit
      else
        added_amount = record.amount.to_d
        added_amount_unit = record.unit
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
        I18n.l(record.created_at, format: :full),
        record.repository_row.repository.team.name,
        record.balance.to_d,
        record.unit
      ]

      if consumption_type == 'Task'
        my_module = record.my_module_repository_row.my_module
        breadcrumbs_data = [
          my_module.experiment.project.name,
          my_module.experiment.name,
          my_module.name,
          my_module.code
        ]
      end

      row_data.insert(10, *breadcrumbs_data)
      row_data
    end
  end
end
