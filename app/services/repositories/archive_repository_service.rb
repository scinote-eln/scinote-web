# frozen_string_literal: true

module Repositories
  class ArchiveRepositoryService < ArchiveRepositoryBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repositories.each do |repository|
          repository.archive!(@user)

          RepositoryActions::ArchiveRowsService.call(repository: repository,
                                                     repository_rows: repository.repository_rows.pluck(:id),
                                                     user: @user,
                                                     team: @team,
                                                     log_activities: false)

          log_activity(:archive_inventory, repository)
        end
      rescue ActiveRecord::RecordNotSaved
        @errors[:archiving_error] = I18n.t('repositories.archive_inventories.unsuccess_flash')
        raise ActiveRecord::Rollback
      end

      self
    end

    private

    def scoped_repositories(ids)
      Repository.where(id: ids, team_id: @team)
    end
  end
end
