# frozen_string_literal: true

module RepositoryColumns
  class DeleteStatusColumnService < RepositoryColumns::CreateColumnService
    def initialize(user:, team:, column:)
      super(user: user, team: team, column_name: nil, repository: column.repository)
      @column = column
    end

    def call; end
  end
end
