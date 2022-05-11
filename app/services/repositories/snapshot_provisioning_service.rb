# frozen_string_literal: true

module Repositories
  class SnapshotProvisioningService
    extend Service

    attr_reader :repository_snapshot, :errors

    def initialize(repository_snapshot:)
      @repository_snapshot = repository_snapshot
      @errors = {}
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction(requires_new: true) do
        repository = @repository_snapshot.original_repository
        has_stock_management = repository.has_stock_management?

        repository.repository_columns.each do |column|
          column.snapshot!(@repository_snapshot)
        end

        repository_rows = repository.repository_rows
                                    .joins(:my_module_repository_rows)
                                    .where(my_module_repository_rows: { my_module: @repository_snapshot.my_module })

        repository_rows.find_each do |original_row|
          row_snapshot = original_row.snapshot!(@repository_snapshot)
          create_stock_consumption_cell_snapshot!(original_row, row_snapshot) if has_stock_management
        end

        @repository_snapshot.ready!
      rescue StandardError => e
        if e.is_a?(ActiveRecord::RecordInvalid)
          @errors[e.record.class.name.underscore] = e.record.errors.full_messages
        else
          @errors[:general] = e.message
        end
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @repository_snapshot
        @errors[:invalid_arguments] =
          { 'repository_snapshot': @repository_snapshot }
          .map do |key, value|
            if value.nil?
              I18n.t('repositories.my_module_assigned_snapshot_service.invalid_arguments', key: key.capitalize)
            end
          end.compact
        return false
      end
      true
    end

    def create_stock_consumption_cell_snapshot!(repository_row, row_snapshot)
      return if repository_row.repository_stock_value.blank?

      my_module_repository_row =
        repository_row.my_module_repository_rows.find { |mrr| mrr.my_module_id == @repository_snapshot.my_module_id }

      stock_unit_item_data =
        if my_module_repository_row.repository_stock_unit_item.present?
          my_module_repository_row.repository_stock_unit_item.data
        else
          repository_row.repository_stock_cell&.repository_stock_value&.repository_stock_unit_item&.data
        end

      stock_unit_item = @repository_snapshot.repository_stock_consumption_column
                                            .repository_stock_unit_items
                                            .find { |item| item.data == stock_unit_item_data }
      RepositoryStockConsumptionValue.create!(
        repository_cell_attributes: {
          repository_column: @repository_snapshot.repository_stock_consumption_column,
          repository_row: row_snapshot
        },
        amount: my_module_repository_row.stock_consumption.to_d,
        repository_stock_unit_item: stock_unit_item
      )
    end
  end
end
