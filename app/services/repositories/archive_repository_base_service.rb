# frozen_string_literal: true

module Repositories
  class ArchiveRepositoryBaseService
    extend Service

    attr_reader :errors

    def initialize(user:, team:, repositories:)
      @user = user
      @team = team
      @repositories = scoped_repositories(repositories)
      @errors = {}
    end

    def call
      raise NotImplementedError
    end

    def succeed?
      @errors.none?
    end

    def error_message
      @errors.values.join(', ')
    end

    private

    def scoped_repositories(_ids)
      raise NotImplementedError
    end

    def valid?
      unless @user
        @errors[:invalid_arguments] =
          { 'user': @user }
          .map do |key, value|
            "Can't find #{key.capitalize}" if value.nil?
          end.compact
      end
      if @repositories.blank?
        @errors[:repositories] = I18n.t('repositories.archive_inventories.invalid_inventories_flash')
      end

      succeed?
    end

    def log_activity(type, repository)
      Activities::CreateActivityService
        .call(activity_type: type,
              owner: @user,
              subject: repository,
              team: @team,
              message_items: {
                repository: repository.id
              })
    end
  end
end
