# frozen_string_literal: true

require 'csv'

class StockReportService
  COLUMNS = %w(
    experiment
    my_module
    repository
    repository_row
    stock_consumption
  ).freeze

  def initialize(project)
    @project = project
  end

  def to_csv
    csv_header = COLUMNS.map { |col| I18n.t("repository_stock_values.stock_report.headers.#{col}") }

    CSV.generate do |csv|
      csv << csv_header
      stock_consumption_entries.each do |stock_consumption_entry|
        csv << stock_consumption_entry
      end
    end
  end

  private

  def stock_consumption_entries
    MyModuleRepositoryRow.includes(:my_module, repository_row: :repository).joins(my_module: { experiment: :project })
                         .where(projects: { id: @project.id })
                         .where.not(stock_consumption: nil).map do |my_module_repository_row|
                           my_module = my_module_repository_row.my_module
                           repository_row = my_module_repository_row.repository_row
                           [
                             "#{my_module.experiment.code} #{my_module.experiment.name}",
                             "#{my_module.code} #{my_module.name}",
                             "#{repository_row.repository.code} #{repository_row.repository.name}",
                             "#{repository_row.code} #{repository_row.name}",
                             "#{my_module_repository_row.formated_stock_consumption}#{my_module_repository_row.repository_stock_unit_item.data}"
                           ]
                         end
  end
end
