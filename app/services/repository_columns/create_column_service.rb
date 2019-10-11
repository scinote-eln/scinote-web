# frozen_string_literal: true

module RepositoryColumns
  class CreateColumnService
    extend Service

    attr_reader :errors, :column

    def initialize(user:, repository:, column_name:, team:)
      @user = user
      @repository = repository
      @column_name = column_name
      @team = team
      @errors = {}
      @column = nil
    end

    def call
      raise NotImplementedError
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @user && @repository
        @errors[:invalid_arguments] =
          { 'user': @user,
            'repository': @repository }
          .map do |key, value|
            "Can't find #{key.capitalize}" if value.nil?
          end.compact
      end

      succeed?
    end

    def create_base_column(type)
      @column = RepositoryColumn.new(
        repository: @repository,
        created_by: @user,
        name: @column_name,
        data_type: type
      )
    end

    def log_activity(type)
      Activities::CreateActivityService
        .call(activity_type: type,
              owner: @user,
              subject: @repository,
              team: @team,
              message_items: {
                repository_column: @column.id,
                repository: @repository.id
              })
    end
  end
end
