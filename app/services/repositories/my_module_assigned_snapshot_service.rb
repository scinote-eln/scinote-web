# frozen_string_literal: true

module Repositories
  class MyModuleAssignedSnapshotService
    extend Service

    attr_reader :repository, :my_module, :user, :errors

    def initialize(repository:, my_module:, user:)
      @repository = repository
      @my_module = my_module
      @user = user
      @errors = {}
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        repository_snapshot = @repository.dup
        repository_snapshot.snapshot = true
        repository_snapshot.original_repository = @repository
        repository_snapshot.my_module = @my_module
        repository_snapshot.save!

        @repository.repository_columns.find_each do |column|
          column_snapshot = column.deep_dup
          column_snapshot.created_at = column.created_at
          column_snapshot.updated_at = DateTime.now
          column_snapshot.repository = repository_snapshot
          column_snapshot.save!
        end

        repository_rows = @repository.repository_rows
                                     .joins(:my_module_repository_rows)
                                     .where(my_module_repository_rows: { my_module: @my_module })

        repository_rows.find_each do |original_row|
          row_snapshot = original_row.deep_dup
          row_snapshot.parent_id = original_row.id
          row_snapshot.created_at = original_row.created_at
          row_snapshot.updated_at = DateTime.now
          row_snapshot.save!

          original_row.repository_cells.each do |cell|
            RepositoryActions::DuplicateCell.new(cell, row_snapshot, @user).call
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[e.record.class.name.underscore] = e.record.errors.full_messages
        raise ActiveRecord::Rollback
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @repository && @my_module && @user
        @errors[:invalid_arguments] =
          { 'repository': @repository,
            'my_module': @my_module,
            'user': @user }
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
