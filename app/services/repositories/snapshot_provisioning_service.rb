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

        repository.repository_columns.each do |column|
          column.snapshot!(@repository_snapshot)
        end

        repository_rows = repository.repository_rows
                                    .joins(:my_module_repository_rows)
                                    .where(my_module_repository_rows: { my_module: @repository_snapshot.my_module })

        repository_rows.find_each do |original_row|
          original_row.snapshot!(@repository_snapshot)
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
  end
end
