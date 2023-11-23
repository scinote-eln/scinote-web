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
    project_id
    experiment_id
    task_id
    stock_amount_balance
    stock_balance_unit
  ).freeze

  def self.to_csv(repository_row_ids)
    csv_header = COLUMNS.map { |col| I18n.t("repository_stock_values.stock_export.headers.#{col}") }
    repository_ledger_records = load_records(repository_row_ids)
    decimal_precision = 0
    if (repository = repository_ledger_records.first&.repository_row&.repository)
      decimal_precision = repository.repository_stock_column.metadata['decimals'].to_i || 0
    end

    CSV.generate do |csv|
      csv << csv_header
      repository_ledger_records.each do |record|
        csv << generate_record_data(record, decimal_precision)
      end
    end
  end

  class << self
    include ActionView::Helpers::NumberHelper

    private

    def load_records(repository_row_ids)
      RepositoryLedgerRecord
        .joins(:repository_row)
        .preload(:user, repository_row: { repository: :team })
        .preload(my_module_repository_row: { my_module: { experiment: { project: :team } } })
        .where(repository_row: { id: repository_row_ids })
        .order(:created_at)
    end

    def generate_record_data(record, precision)
      consumption_type = record.reference_type == 'MyModuleRepositoryRow' ? 'Task' : 'Inventory'

      if (consumption_type == 'Task' && record.amount.positive?) ||
         (consumption_type == 'Inventory' && record.amount.negative?)
        consumed_amount = record.amount.abs
        consumed_amount_unit = record.unit
      else
        added_amount = record.amount.abs
        added_amount_unit = record.unit
      end

      row_data = [
        consumption_type,
        record.repository_row.name,
        record.repository_row.code,
        format_amount(consumed_amount, precision),
        consumed_amount_unit,
        format_amount(added_amount, precision),
        added_amount_unit,
        record.user.full_name,
        I18n.l(record.created_at, format: :full),
        format_amount(record.balance, precision),
        record.unit
      ]
      breadcrumbs_data =
        if consumption_type == 'Task'
          build_breadcrumbs(record)
        else
          Array.new(7)
        end

      row_data.insert(9, *breadcrumbs_data)
      row_data
    end

    def build_breadcrumbs(record)
      if record.my_module_repository_row.present?
        my_module = record.my_module_repository_row.my_module
        [
          my_module.experiment.project.team.name,
          my_module.experiment.project.name,
          my_module.experiment.name,
          my_module.name,
          my_module.experiment.project.code,
          my_module.experiment.code,
          my_module.code
        ]
      elsif record.my_module_references.present?
        [
          Team.find_by(id: record.my_module_references['team_id'])&.name,
          nil,
          nil,
          nil,
          Project.code(record.my_module_references['project_id']),
          Experiment.code(record.my_module_references['experiment_id']),
          MyModule.code(record.my_module_references['my_module_id'])
        ]
      else
        Array.new(7)
      end
    end

    def format_amount(amount, precision)
      # strip insignificant zeros only when precision is zero
      return amount if amount.nil? || !precision.zero?

      number_with_precision(amount, strip_insignificant_zeros: true)
    end
  end
end
