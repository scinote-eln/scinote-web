# frozen_string_literal: true

module RepositoryColumns
  class CreateColumnService
    extend Service
    include Canaid::Helpers::PermissionsHelper

    attr_reader :errors

    def initialize(user, repository, name)
      @user = user
      @repository = repository
      @name = name
      @errors = {}
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

      @errors[:user_without_permissions] = :forbidden unless can_create_repository_columns?(@user, @repository)

      succeed?
    end

    def create_base_column(type)
      @column = RepositoryColumn.new(
        repository_id: @repository_id,
        created_by: @user,
        name: @name,
        data_type: type
      )
    end
  end
end
