# frozen_string_literal: true

module RepositoryColumns
  class DeleteColumnService < RepositoryColumns::ColumnService
    def initialize(user:, team:, column:)
      super(user: user, team: team, column_name: nil, repository: column.repository)
      @column = column
    end

    def call
      ActiveRecord::Base.transaction do
        log_activity(:delete_column_inventory)
        @column.destroy!
      rescue ActiveRecord::RecordNotDestroyed
        errors[:repository_column] = 'record cannot be destroyed'
        raise ActiveRecord::Rollback
      end

      self
    end
  end
end
