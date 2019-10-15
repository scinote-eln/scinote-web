# frozen_string_literal: true

module RepositoryColumns
  class UpdateStatusColumnService < RepositoryColumns::ColumnService
    def initialize(user:, team:, column:, params:)
      super(user: user, repository: column.repository, team: team, column_name: nil)
      @column = column
      @params = params
    end

    def call
      return self unless valid?

      if @column.update(@params)
        log_activity(:edit_column_inventory)
      else
        errors[:repository_column] = @column.errors.messages
      end

      self
    end
  end
end
