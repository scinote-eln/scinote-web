# frozen_string_literal: true

module RepositoryActions
  class ArchiveRowsBaseService
    extend Service

    attr_reader :errors, :column

    def initialize(user:, team:, repository:, repository_rows:)
      @user = user
      @team = team
      @repository = repository
      @repository_rows = scoped_repository_rows(repository_rows)
      @errors = {}
    end

    def call
      raise NotImplementedError
    end

    def succeed?
      @errors.none?
    end

    private

    def scoped_repository_rows(_ids)
      raise NotImplementedError
    end

    def valid?
      unless @user && @repository
        @errors[:invalid_arguments] =
          { 'user': @user,
            'repository': @repository }
          .map do |key, value|
            "Can't find #{key.capitalize}" if value.nil?
          end.compact
      end

      @errors[:repository_rows] = 'Please provide valid rows' if @repository_rows.blank?

      succeed?
    end

    def log_activity(type, row)
      Activities::CreateActivityService
        .call(activity_type: type,
              owner: @user,
              subject: row,
              team: @team,
              message_items: {
                repository_row: row.id
              })
    end
  end
end
