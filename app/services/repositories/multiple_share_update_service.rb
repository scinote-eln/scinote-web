# frozen_string_literal: true

module Repositories
  class MultipleShareUpdateService
    extend Service
    include Canaid::Helpers::PermissionsHelper

    attr_reader :repository, :user, :warnings, :errors

    def initialize(repository_id:,
                   user_id:,
                   team_id:,
                   team_ids_for_share: [],
                   team_ids_for_unshare: [],
                   team_ids_for_update: [])
      @repository = Repository.find_by_id repository_id
      @user = User.find_by_id user_id
      @team = Team.find_by_id team_id
      @team_ids_for_share = team_ids_for_share
      @team_ids_for_unshare = team_ids_for_unshare
      @team_ids_for_update = team_ids_for_update
      @errors = {}
      @warnings = []
    end

    def call
      return self unless valid?

      @team_ids_for_share.each do |share|
        team_repository = TeamRepository.new(repository: @repository,
                                             team_id: share[:id],
                                             permission_level: share[:permission_level])

        if team_repository.save
          log_activity(:share_inventory, team_repository)
        else
          warnings << I18n.t('repositories.multiple_share_service.unable_to_share',
                             repository: @repository.name, team: share[:id])
        end
      end

      @team_ids_for_unshare.each do |team_id|
        team_repository = TeamRepository.where(repository: @repository, team_id: team_id).first

        if team_repository
          log_activity(:unshare_inventory, team_repository)
          team_repository.destroy
        else
          warnings << I18n.t('repositories.multiple_share_service.unable_to_unshare',
                             repository: @repository.name, team: team_id)
        end
      end

      @team_ids_for_update.each do |update|
        team_repository = TeamRepository.where(repository: @repository, team_id: update[:id]).first
        team_repository.permission_level = update[:permission_level] if team_repository

        if team_repository&.save
          log_activity(:update_share_inventory, team_repository)
        else
          warnings << I18n.t('repositories.multiple_share_service.unable_to_update',
                             repository: @repository.name, team: update[:id])
        end
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @user && @repository
        @errors[:invalid_arguments] =
          { 'repository': @repository,
            'user': @user,
            'team': @team }
          .map do |key, value|
            "Can't find #{key.capitalize}" if value.nil?
          end.compact
        return false
      end

      if can_manage_repository?(@user, @repository)
        true
      else
        @errors[:user_without_permissions] =
          ['You are not allowed to share this repository']
        false
      end
    end

    def log_activity(type_of, team_repository)
      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: @user,
              subject: team_repository.repository,
              team: @team,
              message_items: { repository: team_repository.repository.id,
                               team: team_repository.team.id,
                               permission_level:
                                 Extends::SHARED_INVENTORIES_PL_MAPPINGS[team_repository.permission_level.to_sym] })
    end
  end
end
