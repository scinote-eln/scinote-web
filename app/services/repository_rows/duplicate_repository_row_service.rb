# frozen_string_literal: true

module RepositoryRows
  class DuplicateRepositoryRowService
    extend Service

    NOT_COPIED_VALUE_TYPES = %w(RepositoryStockValue RepositoryStockConsumptionValue).freeze

    attr_reader :errors, :repository_row

    def initialize(repository:, source_row:, user:, params:)
      @repository = repository
      @source_row = source_row
      @user = user
      @params = params
      @errors = {}
      @repository_row = nil
    end

    def call
      return self unless mandatory_cells_filled?

      ActiveRecord::Base.transaction do
        @repository_row = @repository.repository_rows.new(name: @params.dig(:repository_row, :name))
        @repository_row.created_by = @user
        @repository_row.last_modified_by = @user
        @repository_row.save!

        provided_cells.each do |column_id, value|
          column = @repository.repository_columns.find_by(id: column_id)
          next if !column || value.blank?

          RepositoryCell.create_with_value!(@repository_row, column, value, @user)
        end

        cells_to_copy.each do |cell|
          RepositoryActions::DuplicateCell.new(cell, @repository_row, @user).call
        end
      rescue ActiveRecord::RecordInvalid => e
        collect_errors(e.record)
        raise ActiveRecord::Rollback
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def provided_cells
      @provided_cells ||= (@params[:repository_cells] || {}).to_h.stringify_keys
    end

    def cells_to_copy
      @cells_to_copy ||= @source_row.repository_cells.includes(:repository_column).reject do |cell|
        NOT_COPIED_VALUE_TYPES.include?(cell.value_type) || provided_cells.key?(cell.repository_column_id.to_s)
      end
    end

    def mandatory_cells_filled?
      copied_column_ids = cells_to_copy.map(&:repository_column_id)
      missing = @repository.repository_columns.where(mandatory: true).reject do |column|
        provided_cells[column.id.to_s].present? || copied_column_ids.include?(column.id)
      end
      return true if missing.empty?

      @errors[:repository_cells] = missing.map do |column|
        I18n.t('repositories.mandatory_column.missing_value', column: column.name)
      end
      false
    end

    def collect_errors(record)
      @errors[record.class.name.underscore] = record.errors.full_messages
      @errors[:name] = record.errors.messages_for(:name) if record.is_a?(RepositoryRow) && record.errors.key?(:name)
      return unless record.is_a?(RepositoryTextValue) && record.not_unique_error?

      @errors[:unique_cells] = { record.repository_cell.repository_column_id => record.errors.messages_for(:data) }
    end
  end
end
