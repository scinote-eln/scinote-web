# frozen_string_literal: true

module Repositories
  class MyModuleAssigningSnapshotService
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
        repository_snapshot = @repository.dup.becomes(RepositorySnapshot)
        repository_snapshot.type = RepositorySnapshot.name
        repository_snapshot.original_repository = @repository
        repository_snapshot.my_module = @my_module
        repository_snapshot.save!

        @repository.repository_columns.each do |column|
          column.snapshot!(repository_snapshot)
        end

        repository_rows = @repository.repository_rows
                                     .joins(:my_module_repository_rows)
                                     .where(my_module_repository_rows: { my_module: @my_module })

        repository_rows.find_each do |original_row|
          original_row.snapshot!(repository_snapshot)
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
