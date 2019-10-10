# frozen_string_literal: true

module RepositoryColumns
  class UpdateStatusColumnService < RepositoryColumns::CreateColumnService
    def initialize(user:, team:, column:, params:)
      super(user: user, repository: column.repository, team: team, column_name: nil)
      @params = params
    end

    def call; end
  end
end
